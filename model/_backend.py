'''from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from torchvision import transforms, models
from PIL import Image
import torch
import io

# Ensure to add DenseNet to the safe globals
torch.serialization.add_safe_globals([models.densenet])

# Load the entire Prototypical Model (architecture + weights)
model = torch.load('prototypical_model.pt', map_location=torch.device('cpu'), weights_only=False)
model.eval()  # Set the model to evaluation mode

# Define your image transformation pipeline
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor()
])

# FastAPI app setup
app = FastAPI()

# Prediction route
@app.post("/predict/")
async def predict(file: UploadFile = File(...)):
    # Read image from the uploaded file
    image_bytes = await file.read()
    image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    input_tensor = transform(image).unsqueeze(0)  # shape: [1, 3, 224, 224]

    # Predict using the Prototypical Model
    with torch.no_grad():
        output = model(input_tensor)  # Assuming the model directly gives the class output

    # Assuming output is a logit or score for classes, apply softmax if necessary
    predicted_class = torch.argmax(output, dim=1).item()

    # Return the predicted class
    return JSONResponse(content={"predicted_class": predicted_class})

# Root route
@app.get("/")
def read_root():
    return {"message": "Welcome to the Eye Disease Classification API!"}'''

from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from torchvision import transforms
import torchvision.models as models
from PIL import Image
import torch
import io

# Ensure to add DenseNet to the safe globals
torch.serialization.add_safe_globals([models.densenet])

# Load the entire Prototypical Model (architecture + weights)
model = torch.load('prototypical_model.pt', map_location=torch.device('cpu'), weights_only=False)
model.eval()  # Set the model to evaluation mode

# Define your image transformation pipeline
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor()
])

# Class-to-Label mapping (adjust this to match your dataset)
class_labels = {
    0: "cataract",
    1: "healthy",
    2: "pterygium",
    3: "glaucoma",
    4: "keratoconus",
    5: "strabismus",
    6: "pink_eye",
    7: "stye",
    8: "trachoma",
    9: "uveitis"
    # You can adjust the class labels based on your dataset classes
}

# FastAPI app setup
app = FastAPI()

# Prediction route
@app.post("/predict/")
async def predict(file: UploadFile = File(...)):
    # Read image from the uploaded file
    image_bytes = await file.read()
    image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    input_tensor = transform(image).unsqueeze(0)  # shape: [1, 3, 224, 224]

    # Predict using the Prototypical Model
    with torch.no_grad():
        output = model(input_tensor)  # Assuming the model directly gives the class output

    # Assuming output is a logit or score for classes, apply softmax if necessary
    predicted_class_id = torch.argmax(output, dim=1).item()  # Get the class ID (index)

    # Map the predicted class ID to its corresponding label
    predicted_class_label = class_labels.get(predicted_class_id, "Unknown Class")

    # Return the predicted class ID and label
    print("Model output shape:", output.shape)
    return JSONResponse(content={
        "predicted_class_id": predicted_class_id,
        "predicted_class_label": predicted_class_label
    })

# Root route
@app.get("/")
def read_root():
    return {"message": "Welcome to the Eye Disease Classification API haha!"}

#uvicorn _backend:app --reload
