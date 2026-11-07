
import torch
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
)

from models.panel_classifier.config import CLASS_NAMES


def evaluate_model(model, loader, device):
    model.eval()

    true_labels = []
    predictions = []

    with torch.no_grad():
        for images, labels in loader:
            images = images.to(device)

            outputs = model(images)
            predicted = outputs.argmax(dim=1)

            true_labels.extend(labels.tolist())
            predictions.extend(predicted.cpu().tolist())

    print(
        "Test accuracy:",
        f"{accuracy_score(true_labels, predictions):.2%}",
    )

    print("\nClassification report:")
    print(
        classification_report(
            true_labels,
            predictions,
            labels=[0, 1],
            target_names=CLASS_NAMES,
            zero_division=0,
        )
    )

    print("Confusion matrix:")
    print(
        confusion_matrix(
            true_labels,
            predictions,
            labels=[0, 1],
        )
    )
