import torch
from diffusers import DiffusionPipeline
import argparse
import os

parser = argparse.ArgumentParser(description="Generate an image using Ideogram 4 on ROCm")
parser.add_argument("--prompt", type=str, default="A highly detailed futuristic city with glowing neon lights, cyberpunk style", help="The image prompt")
parser.add_argument("--output", type=str, default="ideogram_output.png", help="The output image filename")
parser.add_argument("--hf_token", type=str, default=os.getenv("HF_TOKEN"), help="Hugging Face access token (required for gated models)")
args = parser.parse_args()

if not args.hf_token:
    print("Warning: HF_TOKEN is not set. Ideogram 4 is a gated model, so you may need a Hugging Face token to download it.")
    print("You can pass it with --hf_token or set the HF_TOKEN environment variable.")

print("Loading Ideogram 4 (NF4 quantized) on device: cuda (ROCm AMD GPU)...")

# Load the pipeline. Ideogram 4 NF4 requires Hugging Face token authentication.
try:
    pipe = DiffusionPipeline.from_pretrained(
        "ideogram-ai/ideogram-4-nf4",
        torch_dtype=torch.bfloat16,
        token=args.hf_token
    )
    
    # Enable model CPU offloading to save VRAM on unified memory
    pipe.enable_model_cpu_offload()
    
    print(f"Generating image for prompt: '{args.prompt}'")
    # Ideogram 4 generates great images. Let's use default inference steps or specify them.
    image = pipe(
        prompt=args.prompt,
        num_inference_steps=30, # Ideogram usually benefits from more steps compared to Flux-schnell
        guidance_scale=7.5
    ).images[0]
    
    image.save(args.output)
    print(f"Success! Image saved to {args.output}")
except Exception as e:
    print(f"Error loading or running Ideogram 4 model: {e}")
    print("Please make sure you have accepted the license terms on Hugging Face: https://huggingface.co/ideogram-ai/ideogram-4-nf4")
