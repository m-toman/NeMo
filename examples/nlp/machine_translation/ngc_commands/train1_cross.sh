WANDB_API_KEY="$1"

read -r -d '' command << EOF
set -e -x
mkdir /result/nemo_experiments
cd NeMo
git pull
bash reinstall.sh
cd examples/nlp/machine_translation
wandb login ${WANDB_API_KEY}
python create_autoregressive_char_vocabulary.py \
  --input /data/train/cross_labels.txt \
  --output /workspace/cross_labels_char_vocab.txt \
  --characters_to_exclude $'\n' \
  --eos_token EOS \
  --pad_token PAD \
  --bos_token BOS
python enc_dec_nmt.py \
  --config-path=conf \
  --config-name aayn_base_cross_labels_punc_cap \
  trainer.gpus=1
set +e +x
EOF

ngc batch run \
  --instance dgx1v.16g.1.norm \
  --name "ml-model.aayn cross_labels_training" \
  --image "nvcr.io/nvidian/ac-aiapps/speech_translation:latest" \
  --result /result \
  --datasetid 90228:/data \
  --commandline "${command}"