set -xe

DATASET_NAME=xenial-main-amd64
EXP_NAME=${DATASET_NAME}-variable-f1w-regp100w-regn200w-offp95w-offn95w-2
BIN_DIR=data/${DATASET_NAME}/stripped/
DEBUG_DIR=data/${DATASET_NAME}/debug/
TRAIN_BIN_LIST=data/${DATASET_NAME}/train.txt
TEST_BIN_LIST=data/${DATASET_NAME}/test.txt
N2P_PORT=8600
N2P_SLEEP=20
NUM_WORKERS=15

BAP_CACHE_DIR=bap_cache/${DATASET_NAME}/
mkdir -p ${BAP_CACHE_DIR}

# Train varibale
variable_model=models/${EXP_NAME}/variable/
mkdir -p ${variable_model}
python3 py/train_variable.py \
          --bin_list ${TRAIN_BIN_LIST} \
          --bin_dir ${BIN_DIR} \
          --debug_dir ${DEBUG_DIR} \
          --bap_dir ${BAP_CACHE_DIR} \
          --out_model ${variable_model} \
          --reg_num_f 10000 \
          --off_num_f 10000 \
          --reg_num_p 1000000 \
          --reg_num_n 2000000 \
          --off_num_p 950000 \
          --off_num_n 950000 \
          --workers ${NUM_WORKERS}

# Train CRF
crf_model_dir=models/${EXP_NAME}/crf
crf_model=${crf_model_dir}/model
crf_json_dir=${crf_model_dir}/json/
mkdir -p ${crf_model_dir}
mkdir -p ${crf_json_dir}

python3 py/train_crf.py \
          --bin_list ${TRAIN_BIN_LIST} \
          --bin_dir ${BIN_DIR} \
          --debug_dir ${DEBUG_DIR} \
          --bap_dir ${BAP_CACHE_DIR} \
          --out_model ${crf_model} \
          --n2p_train Nice2Predict/bazel-bin/n2p/training/train_json \
          --log_dir ${crf_json_dir} \
          --valid_labels c_valid_labels \
          --workers ${NUM_WORKERS}

# START Nice2Predict
./Nice2Predict/bazel-bin/n2p/json_server/json_server \
        --port ${N2P_PORT} \
        --model ${crf_model} \
        --valid_labels ./c_valid_labels \
        -logtostderr &

sleep ${N2P_SLEEP}

# Evaluate
stats_dir=stats/${EXP_NAME}/
mkdir -p ${stats_dir}

set +xe
echo "Start evaluating"

cat ${TEST_BIN_LIST} | xargs -I % -P ${NUM_WORKERS} python3 py/evaluate.py \
         --binary ${BIN_DIR}/% \
         --debug_info ${DEBUG_DIR}/% \
         --bap ${BAP_CACHE_DIR}/% \
         -two_pass \
         --fp_model ${variable_model} \
         --n2p_url http://localhost:${N2P_PORT} \
         --stat ${stats_dir}/%.stat

set -xe

python3 ./show_metric.py ${stats_dir}

# Kill Nice2Predict server and do not kill the current process
ps aux | grep "./Nice2Predict/bazel-bin/n2p/json_server/json_server" | grep -v grep | awk '{print $2}' | xargs kill -9

# python3 py/predict.py \
#           --binary bintoo/x64_O2/stripped-new/aide \
#           --output ./predicted/x64_O2/aide.output \
#           --elf_modifier cpp/modify_elf.so \
#           -two_pass \
#           --fp_model models/variable/x64_O2/ \
#           --n2p_url http://localhost:8605
