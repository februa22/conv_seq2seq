export PYTHONIOENCODING=UTF-8

# Select the running mode for this script
# * `all`, `train`, `infer_greedy`, `infer_beam`
MODE=all

export DATA_PATH=/data/pos_sejong800k/s2s

export VOCAB_SOURCE=${DATA_PATH}/pos_sejong800k.vocab.inputs.cut
export VOCAB_TARGET=${DATA_PATH}/pos_sejong800k.space.vocab.targets.cut
export TRAIN_SOURCES=${DATA_PATH}/pos_sejong800k.train.inputs.encoded
export TRAIN_TARGETS=${DATA_PATH}/pos_sejong800k.space.train.targets.encoded
export DEV_SOURCES=${DATA_PATH}/pos_sejong800k.dev.inputs.encoded
export DEV_TARGETS=${DATA_PATH}/pos_sejong800k.space.dev.targets.encoded
export TEST_SOURCES=${DATA_PATH}/pos_sejong800k.test.inputs.encoded
export TEST_TARGETS=${DATA_PATH}/pos_sejong800k.space.test.targets.encoded

export TRAIN_STEPS=1000000


export MODEL_DIR=/data/conv_seq2seq_train/pos_conv_seq2seq_slash_base
export PRED_DIR=${MODEL_DIR}/pred
export CUDA_VISIBLE_DEVICES=0

mkdir -p $MODEL_DIR
mkdir -p ${PRED_DIR}

if [ "$MODE" = all ] || [ "$MODE" = train ]; then
  python -m bin.train \
    --config_paths="
        ./example_configs/conv_seq2seq_big.yml,
        ./example_configs/train_seq2seq.yml,
        ./example_configs/text_metrics_bpe.yml" \
    --model_params "
        vocab_source: $VOCAB_SOURCE
        vocab_target: $VOCAB_TARGET" \
    --input_pipeline_train "
      class: ParallelTextInputPipelineFairseq
      params:
        source_files:
          - $TRAIN_SOURCES
        target_files:
          - $TRAIN_TARGETS" \
    --input_pipeline_dev "
      class: ParallelTextInputPipelineFairseq
      params:
        source_files:
          - $DEV_SOURCES
        target_files:
          - $DEV_TARGETS" \
    --batch_size 128 \
    --eval_every_n_steps 5000 \
    --train_steps $TRAIN_STEPS \
    --output_dir $MODEL_DIR
fi

if [ "$MODE" = all ] || [ "$MODE" = infer_greedy ]; then
  ###with greedy search
  python -m bin.infer \
    --tasks "
      - class: DecodeText" \
    --model_dir $MODEL_DIR \
    --model_params "
      inference.beam_search.beam_width: 1 
      decoder.class: seq2seq.decoders.ConvDecoderFairseq" \
    --input_pipeline "
      class: ParallelTextInputPipelineFairseq
      params:
        source_files:
          - $TEST_SOURCES" \
    > ${PRED_DIR}/predictions.beam1.txt

  ./bin/tools/multi-bleu.perl ${TEST_TARGETS} < ${PRED_DIR}/predictions.beam1.txt
fi

if [ "$MODE" = all ] || [ "$MODE" = infer_beam ]; then
  ###with beam search
  python -m bin.infer \
    --tasks "
      - class: DecodeText
      - class: DumpBeams
        params:
          file: ${PRED_DIR}/beams.npz" \
    --model_dir $MODEL_DIR \
    --model_params "
      inference.beam_search.beam_width: 5 
      decoder.class: seq2seq.decoders.ConvDecoderFairseqBS" \
    --input_pipeline "
      class: ParallelTextInputPipelineFairseq
      params:
        source_files:
          - $TEST_SOURCES" \
    > ${PRED_DIR}/predictions.beam5.txt

  ./bin/tools/multi-bleu.perl ${TEST_TARGETS} < ${PRED_DIR}/predictions.beam5.txt
fi
