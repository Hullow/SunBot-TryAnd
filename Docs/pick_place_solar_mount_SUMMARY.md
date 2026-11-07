# How the pick-and-place program works

We had 52 recordings of a person guiding the robot arm through picking up a
green panel and placing it on a target. Each recording logs the arm's six
joint angles (including the gripper) 30 times per second.

There is no AI or learning in the program. It replays one good recording:

1. **Pick a clean recording.** The program looks at the gripper signal. A clean
   run opens the gripper once, closes it once (the grasp) and opens it once more
   (the release). It also checks that the gripper stayed slightly open while
   closed, which shows it was holding the panel.
2. **Reduce it to key poses.** It keeps 8 arm positions at the important
   moments: start, open, approach, grasp, lift, carry, release, back away.
3. **Replay the poses slowly.** It moves smoothly from one pose to the next,
   pausing between them, at an adjustable speed.

Safety: by default the program only prints the plan and never moves the arm.
Real motion needs an explicit flag and a countdown. Every move stays within
the range seen in the recordings and is limited in size per step. Ctrl+C
stops the arm.

Limitation: the robot doesn't look at anything. It repeats the same motion
every time, so the panel must start exactly where it was in that recording.
