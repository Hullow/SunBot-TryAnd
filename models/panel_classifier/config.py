from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = PROJECT_ROOT / "datasets/panel_classifier/images"
MODEL_PATH = PROJECT_ROOT / "models/panel_classifier/panel_model.pt"

# Hyperparameters
IMAGE_SIZE = 224
BATCH_SIZE = 16
LEARNING_RATE = 0.0001

CV_FOLDS = 2
CV_EPOCHS = 5
FINAL_EPOCHS = 15

TEST_SIZE = 0.2
RANDOM_SEED = 42

CLASS_NAMES = ["not_panel", "panel"]
NUM_CLASSES = 2