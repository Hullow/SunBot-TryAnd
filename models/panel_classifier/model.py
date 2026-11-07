
from torch import nn
from torchvision.models import resnet18, ResNet18_Weights

from models.panel_classifier.config import NUM_CLASSES


def create_model():
    model = resnet18(weights=ResNet18_Weights.DEFAULT)

    model.fc = nn.Linear(
        model.fc.in_features,
        NUM_CLASSES,
    )

    return model
