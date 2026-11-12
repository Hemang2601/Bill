import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageOps

def generate_futuristic_suite():
    master_src = 'C:/Users/Admin/.gemini/antigravity/brain/984986f9-e387-41a0-9ff9-9ba97a78e1bf/shree_shakti_electric_app_icon_wide_padding_1794475105284.jpg'
    master_img = Image.open(master_src).convert('RGBA')
    W, H = master_img.size
    CX, CY = W // 2, H // 2

    # =========================================================================
    # 1. GENERATE ADAPTIVE BACKGROUND (Clean Deep Navy Radial Glow + Rings)
    # =========================================================================
    bg = Image.new('RGBA', (W, H), (0, 0, 0, 255))
    
    # Generate continuous radial navy gradient
    y, x = np.ogrid[:H, :W]
    dist = np.sqrt((x - CX)**2 + (y - CY)**2)
    max_d = np.sqrt(CX**2 + CY**2)
    norm_d = np.clip(dist / max_d, 0.0, 1.0)
    
    # Vertical gradient factor (top is slightly lighter than bottom)
    vert_factor = y / H

    # Colors:
    # Center: (10, 42, 95)
    # Top corners: (5, 21, 55)
    # Bottom corners: (1, 9, 28)
    r = (12 * (1 - norm_d)**1.4 + 4 * (1 - vert_factor) + 1 * vert_factor).astype(np.uint8)
    g = (46 * (1 - norm_d)**1.4 + 20 * (1 - vert_factor) + 9 * vert_factor).astype(np.uint8)
    b = (105 * (1 - norm_d)**1.4 + 52 * (1 - vert_factor) + 26 * vert_factor).astype(np.uint8)
    a = np.full((H, W), 255, dtype=np.uint8)
    bg_np = np.stack([r, g, b, a], axis=-1)
    bg = Image.fromarray(bg_np, mode='RGBA')

    # Add soft radial energy glow at center
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([CX - 400, CY - 400, CX + 400, CY + 400], fill=(0, 130, 240, 70))
    gd.ellipse([CX - 250, CY - 250, CX + 250, CY + 250], fill=(0, 180, 255, 55))
    glow = glow.filter(ImageFilter.GaussianBlur(90))
    bg = Image.alpha_composite(bg, glow)

    # Concentric orbital rings on background
    rings = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rings)
    for rad in [280, 340, 400, 460, 520]:
        rd.ellipse([CX - rad, CY - rad, CX + rad, CY + rad], outline=(0, 140, 255, 18), width=2)
    rings = rings.filter(ImageFilter.GaussianBlur(1))
    bg = Image.alpha_composite(bg, rings)

    # =========================================================================
    # 2. GENERATE ADAPTIVE FOREGROUND (Emblem on Transparent Background)
    # =========================================================================
    # We create a smooth mask isolating the central emblem and its ambient glow
    mask = Image.new('L', (W, H), 0)
    md = ImageDraw.Draw(mask)
    
    # Outer radius covering the hexagon + glow + bolt tips (tip extends up to radius ~340)
    # The hexagon is ~540x580 px, radius is ~320 px.
    # We draw an ellipse / smooth polygon matching the hexagon with generous padding:
    # Radius 335 at 0, 360 at tips
    md.ellipse([CX - 325, CY - 335, CX + 325, CY + 335], fill=255)
    # Smooth Gaussian blur for the mask boundary to feather out the blue aura cleanly
    mask = mask.filter(ImageFilter.GaussianBlur(18))

    # Apply mask to master image
    fg = master_img.copy()
    fg.putalpha(mask)

    # Save to assets/icons and artifact directory
    assets_dir = 'assets/icons'
    os.makedirs(assets_dir, exist_ok=True)
    artifact_dir = r'C:/Users/Admin/.gemini/antigravity/brain/984986f9-e387-41a0-9ff9-9ba97a78e1bf'

    master_img.save(os.path.join(assets_dir, 'app_icon.png'), 'PNG')
    fg.save(os.path.join(assets_dir, 'app_icon_foreground.png'), 'PNG')
    bg.save(os.path.join(assets_dir, 'app_icon_background.png'), 'PNG')

    master_img.save(os.path.join(artifact_dir, 'app_icon_master_1024.png'), 'PNG')
    fg.save(os.path.join(artifact_dir, 'app_icon_foreground_1024.png'), 'PNG')
    bg.save(os.path.join(artifact_dir, 'app_icon_background_1024.png'), 'PNG')

    print("Master 1024x1024 PNG, Foreground, and Background saved successfully!")

if __name__ == '__main__':
    generate_futuristic_suite()
