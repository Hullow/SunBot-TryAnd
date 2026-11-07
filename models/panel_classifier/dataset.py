
from torchvision import datasets, transforms

from models.panel_classifier.config import DATA_DIR, IMAGE_SIZE


def create_dataset():
    transform = transforms.Compose([
        transforms.Resize((IMAGE_SIZE, IMAGE_SIZE)),
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225],
        ),
    ])

    dataset = datasets.ImageFolder(
        root=DATA_DIR,
        transform=transform,
    )

    expected_classes = ["not_panel", "panel"]

    if dataset.classes != expected_classes:
        raise ValueError(
            f"Expected classes {expected_classes}, "
            f"but found {dataset.classes}"
        )

    return dataset
