# Set up the SO-ARM101 on another computer

For the same leader and follower arms, install LeRobot on the second computer and copy the two calibration files. The motor IDs are stored on the motors, so you do not need to run `setup-motors` again.

## 1. Install the same LeRobot checkout

Copy `/Users/francis/Robotics/Makefile` to a `Robotics` folder on the second computer. From that folder, run:

```bash
git clone https://github.com/huggingface/lerobot.git
git -C lerobot checkout eecd7f4b91cd77af9f15b1d633c067756ad11a15
uv venv --python 3.12 .venv
uv pip install --python .venv/bin/python -e './lerobot[feetech]'
```

These commands assume `uv` is installed. See the [LeRobot installation guide](https://huggingface.co/docs/lerobot/en/installation) if you need to install it or its prerequisites.

## 2. Copy calibration

Copy these two files from this Mac to the same paths under the new computer's home directory:

```text
~/.cache/huggingface/lerobot/calibration/robots/so_follower/my_awesome_follower_arm.json
~/.cache/huggingface/lerobot/calibration/teleoperators/so_leader/my_awesome_leader_arm.json
```

Create the destination directories if needed. Keep the same arm IDs (`my_awesome_follower_arm` and `my_awesome_leader_arm`) in the Makefile.

## 3. Find ports and test teleoperation

Connect and power both arms. From the `Robotics` folder, run:

```bash
.venv/bin/lerobot-find-port
```

Identify the follower and leader ports, then replace the two hardcoded `/dev/tty.usbmodem...` values in the Makefile if they differ. Run:

```bash
make teleop
```

## Local settings to check

- This Mac's LeRobot checkout changes the follower `P_Coefficient` from 16 to 8 in `lerobot/src/lerobot/robots/so_follower/so_follower.py`. A fresh clone uses 16 unless you carry over that edit.
- Before using `make record` or `make eval`, run `make camera-check` and verify the camera indices in the Makefile. They may differ on the second computer.

See the [LeRobot SO-101 guide](https://huggingface.co/docs/lerobot/en/so101) for motor setup and calibration details.
