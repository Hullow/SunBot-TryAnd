# Prompt: build a supervised SO-101 pick-and-place program

Build a small, reviewable program for an SO-101 follower arm to pick up the
solar-mount part and place it in the target area. First inspect the current
machine's project checkout, setup instructions, and hardware configuration.
Do not assume file paths, serial ports, camera indices, calibration IDs, or
software versions from another computer.

## Inspect first

- Read the current project's `Makefile`/setup guide and the relevant
  SO-101/LeRobot control code before editing anything. If the checkout or
  hardware setup is missing, explain what's needed; do not use machine-specific
  paths from this prompt.
- Online dataset repo: `Hullow/act_so101_pick_and_place_solar_mount_20261107_154702`
  at revision `e595d721ef84ca18654f0fbbb4863d45ba11b491`. Load it directly from
  the Hugging Face Hub; do not rely on a local dataset cache or root path.
- Dataset facts: 52 episodes, 21,090 frames, 30 fps, one 640x480 gripper camera,
  six joint position actions and six joint position observations.
- The target hardware is an SO-101 follower arm. Discover its current serial
  port, camera, calibration ID, and available teleoperator from the setup on
  this machine. Verify all of them before execution.
- The task metadata in the original dataset incorrectly says “pick the lego
  brick and put it in the bowl.” The real task is a solar-mount part and target
  area.
- The object to grasp is a panel with a cube taped on top; the panel is painted
  green. Use this description when examining demonstrations and choosing a
  grasp. Do not treat the cube as a separate object.

## Goal

Create a program that can execute a repeatable pick-and-place motion on this
specific setup: grasp the green panel using the cube taped on top as the
grasping feature, then place the panel in the target area. Prefer a trajectory derived from a clean successful recorded
demonstration, with conservative interpolation and a clear pause between
approach, grasp, lift, transfer, release, and retreat. Do not guess joint
targets, object coordinates, gripper thresholds, or workspace boundaries.
Inspect the episode data and identify a candidate successful episode, then
show the extracted waypoints and ask me to confirm any physical positions or
gripper conventions that the recording cannot establish reliably.

## Constraints

- Do not actuate the robot during coding, calibration inspection, or tests.
- Do not invent Cartesian control if this SO-101 setup only exposes joint
  position control. Use the project's supported LeRobot interfaces.
- Make the first execution dry-run only: print the planned waypoints, timing,
  gripper commands, and safety checks without connecting to the motors.
- Add a conspicuous explicit `--execute` switch for physical motion. Require a
  short operator countdown and retain a readily reachable emergency stop.
- Bound joint targets to the robot's configured limits; include timeout,
  disconnect, and exception handling that stops motion safely.
- Keep the implementation narrow. Do not modify LeRobot library code or the
  existing Makefile target unless necessary; explain any change.

## Deliverables

1. A short design note describing the chosen demonstration, waypoints, timing,
   grasp/release interpretation, and what still needs physical confirmation.
2. The runnable script and exact dry-run command.
3. A small verification using recorded data or a mocked robot interface. Do not
   test by moving the physical arm.
4. A concise supervised commissioning sequence for me to follow after I review
   and confirm the dry run.

Start by reporting what the recordings establish and what they do not. Then
implement the dry-run path before adding physical execution.
