export PATH := $(CURDIR)/.venv/bin:$(PATH)

EPISODE ?= 0
LEROBOT_HOME ?= $(HOME)/.cache/huggingface/lerobot
RESUME ?=

camera-check:
    lerobot-find-cameras opencv

calibrate-follower:
    lerobot-calibrate \
        --robot.type=so101_follower \
        --robot.port=/dev/tty.usbmodem5B421347741 \
        --robot.id=my_awesome_follower_arm

calibrate-leader:
    lerobot-calibrate \
        --teleop.type=so101_leader \
        --teleop.port=/dev/tty.usbmodem5B421340811 \
        --teleop.id=my_awesome_leader_arm

# delete:
#   lerobot-edit-dataset \
#       --repo_id Hullow/act_so101_pick_and_place_solar_panel/ \
#       --operation.type delete_episodes \
#       --operation.episode_indices "[25]"

docs:
    .venv/bin/doc-builder preview lerobot lerobot/docs/source/ && open http://localhost:5173/index

eval:
    lerobot-rollout \
        --strategy.type=episodic \
        --robot.type=so101_follower \
        --robot.port=/dev/tty.usbmodem5B421347741 \
        --robot.id=my_awesome_follower_arm \
        --robot.cameras='{"gripper": {"type": "opencv", "index_or_path": 1, "width": 640, "height": 360, "fps": 30}, "overhead": {"type": "opencv", "index_or_path": 0, "width": 640, "height": 360, "fps": 30}}' \
        --display_data=false \
        --policy.path=Hullow/act_so101_pick_and_place_solar_panel \
        --device=mps \
        --inference.type=queue \
        --use_torch_compile=true \
        --dataset.single_task="pick up the solar panel and place it on the mounting frame" \
        --dataset.push_to_hub=False \
        --dataset.streaming_encoding=true \
        --dataset.rgb_encoder.vcodec=hevc_videotoolbox \
        --dataset.repo_id=$(DATASET) \
        --dataset.num_episodes=3 \
        --dataset.episode_time_s=15 \
        $(RESUME)

eval-resume: RESUME=--resume=true
eval-resume: eval

record:
    lerobot-record \
        --robot.type=so101_follower \
        --robot.port=/dev/tty.usbmodem5B421347741 \
        --robot.id=my_awesome_follower_arm \
        --robot.cameras='{"overhead": {"type": "opencv", "index_or_path": 0, "width": 640, "height": 480, "fps": 30}, "gripper": {"type": "opencv", "index_or_path": 1, "width": 1920, "height": 1080, "fps": 30}}' \
        --teleop.type=so101_leader \
        --teleop.port=/dev/tty.usbmodem5B421340811 \
        --teleop.id=my_awesome_leader_arm \
        --display_data=false \
        --dataset.streaming_encoding=true \
        --dataset.encoder_threads=2 \
        --dataset.rgb_encoder.vcodec=auto \
        --dataset.push_to_hub=False \
        --dataset.repo_id=Hullow/so101_pick_and_place_solar_panel \
        --dataset.episode_time_s=20 \
        --dataset.reset_time_s=20 \
        --dataset.num_episodes=50 \
        --dataset.single_task="pick up the miniature solar panel and place it on the mounting frame" \
        $(RESUME)


resume-record: RESUME=--resume=true
resume-record: record

replay: # replays episode 0 by default, otherwise select with replay EPISODE=X
    lerobot-replay \
        --robot.type=so101_follower \
        --robot.port=/dev/tty.usbmodem5B421347741 \
        --robot.id=my_awesome_follower_arm \
        --robot.disable_torque_on_disconnect=false \
        --dataset.repo_id=Hullow/act_so101_pick_and_place_solar_panel \
        --dataset.episode=$(EPISODE)

setup-follower-motors:
    lerobot-setup-motors \
        --robot.type=so101_follower \
        --robot.port=/dev/tty.usbmodem5B421347741

setup-leader-motors:
    lerobot-setup-motors \
        --robot.type=so101_follower \
        --robot.port=/dev/tty.usbmodem5B421340811

teleop:
    lerobot-teleoperate \
        --robot.type=so101_follower \
        --robot.port=/dev/tty.usbmodem5B421347741 \
        --robot.id=my_awesome_follower_arm \
        --teleop.type=so101_leader \
        --teleop.port=/dev/tty.usbmodem5B421340811 \
        --teleop.id=my_awesome_leader_arm \
        --display_data=false

# ---- Training -------------------------------------------------------------
# Dataset must exist locally (it is auto-pushed to a PRIVATE Hub repo on first
# remote run) or already be on the Hub.
DATASET      ?= Hullow/so101_pick_and_place_solar_panel
POLICY_REPO  ?= Hullow/act_so101_pick_and_place_solar_panel
JOB_NAME     ?= act_so101_pick_and_place_solar_panel
FLAVOR       ?= h200
STEPS        ?= 30000   # ~10 epochs over 23,690 frames at batch 8
BATCH_SIZE   ?= 8
SAVE_FREQ    ?= 5000
NUM_WORKERS  ?= 16      # h200 flavor has 23 vCPU; ACT at BS8 is dataloader-bound
JOB_TIMEOUT  ?= 2h
TRAIN_EXTRA  ?=

# WANDB_API_KEY must be exported (or in ~/.netrc) so the pod gets it: grab it
# from https://wandb.ai/authorize, or run `make train-h200 WANDB=false`.
WANDB ?= true

check-wandb:
    @if [ "$(WANDB)" = "true" ] && [ -z "$$WANDB_API_KEY" ] && ! grep -qs api.wandb.ai $$HOME/.netrc; then \
        echo "No WANDB_API_KEY found. Run: export WANDB_API_KEY=<key from https://wandb.ai/authorize>"; \
        echo "(or disable logging with: make $(MAKECMDGOALS) WANDB=false)"; \
        exit 1; \
    fi

# Train ACT on HF Jobs. Streams logs; Ctrl-C detaches without cancelling the job.
# Checkpoints are pushed to POLICY_REPO every SAVE_FREQ steps, so nothing is lost
# if the pod dies (unlike the wiped Colab run).
train-h200: check-wandb
    lerobot-train \
        --dataset.repo_id=$(DATASET) \
        --policy.type=act \
        --policy.repo_id=$(POLICY_REPO) \
        --policy.push_to_hub=true \
        --policy.license=mit \
        --job_name=$(JOB_NAME) \
        --output_dir=outputs/train/$(JOB_NAME) \
        --batch_size=$(BATCH_SIZE) \
        --steps=$(STEPS) \
        --num_workers=$(NUM_WORKERS) \
        --save_freq=$(SAVE_FREQ) \
        --save_checkpoint_to_hub=true \
        --wandb.enable=$(WANDB) \
        --job.target=$(FLAVOR) \
        --job.timeout=$(JOB_TIMEOUT) \
        $(TRAIN_EXTRA)

# Same run, submit-and-exit instead of streaming logs.
train-h200-detached: TRAIN_EXTRA += --job.detach=true
train-h200-detached: train-h200

# Resume the remote run from the latest checkpoint pushed to POLICY_REPO.
train-h200-resume: TRAIN_EXTRA += --config_path=$(POLICY_REPO) --resume=true
train-h200-resume: train-h200

# Local (this Mac) training, for smoke tests only: make train-local STEPS=100
train-local: check-wandb
    lerobot-train \
        --dataset.repo_id=$(DATASET) \
        --policy.type=act \
        --policy.device=mps \
        --policy.push_to_hub=false \
        --job_name=$(JOB_NAME) \
        --output_dir=outputs/train/$(JOB_NAME)_local \
        --batch_size=$(BATCH_SIZE) \
        --steps=$(STEPS) \
        --save_freq=$(SAVE_FREQ) \
        --wandb.enable=$(WANDB) \
        $(TRAIN_EXTRA)

# Upload the dataset to the Hub explicitly (train-h200 does this automatically
# on first run, but as a PRIVATE repo).
push-dataset:
    .venv/bin/python -c "from lerobot.datasets.lerobot_dataset import LeRobotDataset; \
        LeRobotDataset('$(DATASET)').push_to_hub(private=True, tags=['lerobot'])"

# Watch a running job: make job-logs JOB=<job_id>
job-list:
    hf jobs ps -a

job-logs:
    hf jobs logs $(JOB)

job-cancel:
    hf jobs cancel $(JOB)

# upload-dataset:
#    hf upload Hullow/pick_and_place_solar_panel \
#        ~/.cache/huggingface/lerobot/{repo-id} --repo-type dataset

# upload-policy:
#    hf upload Hullow/pick_and_place_solar_panel \
#        outputs/train/act_so101_pick_and_place_solar_panel_policy/checkpoints/last/pretrained_model/

# opens an episode in Rerun Viewer. Episode 0 by default, otherwise select with viz EPISODE=X
viz:
    lerobot-dataset-viz \
        --repo-id=$(DATASET) \
        --root=$(LEROBOT_HOME)/$(DATASET) \
        --mode=local \
        --episode-index=$(EPISODE)

.PHONY: cameras calibrate-follower calibrate-leader delete docs eval \
record record-resume setup-follower-motors setup-leader-motors \
replay teleop upload viz check-wandb train-h200 train-h200-detached \
train-h200-resume train-local push-dataset job-list job-logs job-cancel
