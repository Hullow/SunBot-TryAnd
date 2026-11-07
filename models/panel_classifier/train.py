
"""Train the SunBot solar panel classifier."""

import random

import numpy as np
import torch
from sklearn.model_selection import StratifiedKFold, train_test_split
from torch import nn
from torch.utils.data import DataLoader, Subset

from models.panel_classifier.config import (
    BATCH_SIZE,
    CLASS_NAMES,
    CV_EPOCHS,
    CV_FOLDS,
    FINAL_EPOCHS,
    LEARNING_RATE,
    MODEL_PATH,
    RANDOM_SEED,
    TEST_SIZE,
)
from models.panel_classifier.dataset import create_dataset
from models.panel_classifier.model import create_model
from models.panel_classifier.evaluate import evaluate_model


DEVICE = torch.device(
    "cuda" if torch.cuda.is_available() else "cpu"
)


def train_epoch(model, loader, optimizer):
    """Train the model for one epoch."""
    model.train()
    criterion = nn.CrossEntropyLoss()
    total_loss = 0.0

    for images, labels in loader:
        images = images.to(DEVICE)
        labels = labels.to(DEVICE)

        optimizer.zero_grad()

        outputs = model(images)
        loss = criterion(outputs, labels)

        loss.backward()
        optimizer.step()

        total_loss += loss.item() * len(images)

    return total_loss / len(loader.dataset)


def accuracy(model, loader):
    """Calculate validation accuracy."""
    model.eval()
    correct = 0
    total = 0

    with torch.no_grad():
        for images, labels in loader:
            images = images.to(DEVICE)
            labels = labels.to(DEVICE)

            outputs = model(images)
            predictions = outputs.argmax(dim=1)

            correct += (predictions == labels).sum().item()
            total += len(labels)

    return correct / total


def train_model(train_data, epochs):
    """Create and train a ResNet18 model."""
    model = create_model().to(DEVICE)

    optimizer = torch.optim.AdamW(
        model.parameters(),
        lr=LEARNING_RATE,
    )

    loader = DataLoader(
        train_data,
        batch_size=BATCH_SIZE,
        shuffle=True,
        num_workers=0,
    )

    for epoch in range(epochs):
        loss = train_epoch(model, loader, optimizer)

        print(
            f"Epoch {epoch + 1}/{epochs} "
            f"| Loss: {loss:.4f}"
        )

    return model


def main():
    """Run cross-validation, final training, and testing."""

    # Reproducibility
    random.seed(RANDOM_SEED)
    np.random.seed(RANDOM_SEED)
    torch.manual_seed(RANDOM_SEED)

    # Load images and labels
    dataset = create_dataset()
    labels = np.array(dataset.targets)
    indices = np.arange(len(dataset))

    print(f"Device: {DEVICE}")
    print(f"Total images: {len(dataset)}")
    print(f"Classes: {dataset.classes}")

    # 80% development / 20% test
    train_idx, test_idx = train_test_split(
        indices,
        test_size=TEST_SIZE,
        stratify=labels,
        random_state=RANDOM_SEED,
    )

    print(f"Training images: {len(train_idx)}")
    print(f"Test images: {len(test_idx)}")

    # 2-fold cross-validation on training data
    cv = StratifiedKFold(
        n_splits=CV_FOLDS,
        shuffle=True,
        random_state=RANDOM_SEED,
    )

    scores = []

    for fold, (fit_idx, val_idx) in enumerate(
            cv.split(train_idx, labels[train_idx]),
            start=1,
    ):
        print(f"\nFold {fold}/{CV_FOLDS}")

        train_subset = Subset(
            dataset,
            train_idx[fit_idx].tolist(),
        )

        val_subset = Subset(
            dataset,
            train_idx[val_idx].tolist(),
        )

        model = train_model(
            train_subset,
            CV_EPOCHS,
        )

        val_loader = DataLoader(
            val_subset,
            batch_size=BATCH_SIZE,
            num_workers=0,
        )

        score = accuracy(model, val_loader)
        scores.append(score)

        print(f"Validation accuracy: {score:.2%}")

    print(
        f"\nMean CV accuracy: {np.mean(scores):.2%}"
    )

    # Train a new model using all 80% training images
    print("\nFinal training")

    final_data = Subset(
        dataset,
        train_idx.tolist(),
    )

    model = train_model(
        final_data,
        FINAL_EPOCHS,
    )

    # Evaluate once on the held-out 20% test set
    test_data = Subset(
        dataset,
        test_idx.tolist(),
    )

    test_loader = DataLoader(
        test_data,
        batch_size=BATCH_SIZE,
        num_workers=0,
    )

    print("\nTest results")
    evaluate_model(model, test_loader, DEVICE)

    # Save trained model
    MODEL_PATH.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    torch.save(
        {
            "model_state_dict": model.state_dict(),
            "class_names": CLASS_NAMES,
        },
        MODEL_PATH,
    )

    print(f"\nSaved model: {MODEL_PATH}")


if __name__ == "__main__":
    main()
