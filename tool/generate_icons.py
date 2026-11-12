import os
import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont

def generate_all_icons():
    # 1. Load Master Assets
    master_path = 'assets/icons/app_icon.png'
    fg_path = 'assets/icons/app_icon_foreground.png'
    bg_path = 'assets/icons/app_icon_background.png'

    master = Image.open(master_path).convert('RGBA')
    foreground = Image.open(fg_path).convert('RGBA')
    background = Image.open(bg_path).convert('RGBA')

    # 2. Windows ICO multi-resolution asset (16x16 up to 256x256)
    ico_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    windows_ico_dir = 'windows/runner/resources'
    os.makedirs(windows_ico_dir, exist_ok=True)
    master.save(os.path.join(windows_ico_dir, 'app_icon.ico'), format='ICO', sizes=ico_sizes)
    master.save('assets/icons/app_icon.ico', format='ICO', sizes=ico_sizes)
    print("Generated Windows ICO assets.")

    # 3. Android Mipmap Densities
    densities = {
        'mipmap-mdpi': (48, 108),
        'mipmap-hdpi': (72, 162),
        'mipmap-xhdpi': (96, 216),
        'mipmap-xxhdpi': (144, 324),
        'mipmap-xxxhdpi': (192, 432)
    }

    res_dir = 'android/app/src/main/res'

    for folder, (icon_size, fg_size) in densities.items():
        target_dir = os.path.join(res_dir, folder)
        os.makedirs(target_dir, exist_ok=True)
        
        # Standard ic_launcher.png (Squircle / Rounded Rectangle)
        std_icon = master.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
        mask = Image.new('L', (icon_size, icon_size), 0)
        m_draw = ImageDraw.Draw(mask)
        corner_r = int(icon_size * 0.22)
        m_draw.rounded_rectangle([0, 0, icon_size, icon_size], radius=corner_r, fill=255)
        rounded_icon = Image.new('RGBA', (icon_size, icon_size), (0, 0, 0, 0))
        rounded_icon.paste(std_icon, (0, 0), mask)
        rounded_icon.save(os.path.join(target_dir, 'ic_launcher.png'), 'PNG')
        
        # Circular ic_launcher_round.png (Pixel / Moto / AOSP)
        round_mask = Image.new('L', (icon_size, icon_size), 0)
        rm_draw = ImageDraw.Draw(round_mask)
        rm_draw.ellipse([0, 0, icon_size, icon_size], fill=255)
        round_icon = Image.new('RGBA', (icon_size, icon_size), (0, 0, 0, 0))
        round_icon.paste(std_icon, (0, 0), round_mask)
        round_icon.save(os.path.join(target_dir, 'ic_launcher_round.png'), 'PNG')
        
        # Adaptive foreground per density
        fg_icon = foreground.resize((fg_size, fg_size), Image.Resampling.LANCZOS)
        fg_icon.save(os.path.join(target_dir, 'ic_launcher_foreground.png'), 'PNG')

    print("Generated Android mipmap assets.")

    # 4. Drawable resources for adaptive icon background and foreground
    drawable_dir = os.path.join(res_dir, 'drawable')
    os.makedirs(drawable_dir, exist_ok=True)
    background.resize((432, 432), Image.Resampling.LANCZOS).save(
        os.path.join(drawable_dir, 'ic_launcher_background.png'), 'PNG'
    )
    foreground.resize((432, 432), Image.Resampling.LANCZOS).save(
        os.path.join(drawable_dir, 'ic_launcher_foreground.png'), 'PNG'
    )

    # Drawable-v21
    drawable_v21 = os.path.join(res_dir, 'drawable-v21')
    os.makedirs(drawable_v21, exist_ok=True)
    background.resize((432, 432), Image.Resampling.LANCZOS).save(
        os.path.join(drawable_v21, 'ic_launcher_background.png'), 'PNG'
    )
    foreground.resize((432, 432), Image.Resampling.LANCZOS).save(
        os.path.join(drawable_v21, 'ic_launcher_foreground.png'), 'PNG'
    )
    print("Generated Android drawable resources.")

    # 5. Adaptive XML definition for Android 8.0+ (API 26+)
    anydpi_dir = os.path.join(res_dir, 'mipmap-anydpi-v26')
    os.makedirs(anydpi_dir, exist_ok=True)

    xml_content = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
"""
    with open(os.path.join(anydpi_dir, 'ic_launcher.xml'), 'w', encoding='utf-8') as f:
        f.write(xml_content)

    with open(os.path.join(anydpi_dir, 'ic_launcher_round.xml'), 'w', encoding='utf-8') as f:
        f.write(xml_content)
    print("Generated Android adaptive XMLs.")

    # 6. Copy master previews to artifact directory
    artifact_dir = r'C:/Users/Admin/.gemini/antigravity/brain/984986f9-e387-41a0-9ff9-9ba97a78e1bf'
    master.save(os.path.join(artifact_dir, 'app_icon_master_1024.png'), 'PNG')
    foreground.save(os.path.join(artifact_dir, 'app_icon_foreground_1024.png'), 'PNG')
    background.save(os.path.join(artifact_dir, 'app_icon_background_1024.png'), 'PNG')

    # 7. Generate Android Home Screen Simulation Showcase (1600x900)
    create_home_screen_simulation(master, artifact_dir)

def create_home_screen_simulation(master, artifact_dir):
    canvas_w, canvas_h = 1600, 900
    showcase = Image.new('RGBA', (canvas_w, canvas_h), (11, 15, 25, 255))
    draw = ImageDraw.Draw(showcase)

    # Left Section: Master Icon Showcase (0 to 650)
    # Master card background
    draw.rounded_rectangle([60, 60, 560, 840], radius=24, fill=(18, 24, 38, 255), outline=(37, 99, 235, 120), width=2)
    draw.text((90, 85), "MASTER LAUNCHER ICON (1024 x 1024)", fill=(241, 245, 249, 255))
    draw.text((90, 110), "Shree Shakti Electric | Official Futuristic Branding", fill=(100, 116, 139, 255))

    master_thumb = master.resize((420, 420), Image.Resampling.LANCZOS)
    # Apply rounded corner
    mask_thumb = Image.new('L', (420, 420), 0)
    ImageDraw.Draw(mask_thumb).rounded_rectangle([0, 0, 420, 420], radius=92, fill=255)
    rounded_thumb = Image.new('RGBA', (420, 420), (0, 0, 0, 0))
    rounded_thumb.paste(master_thumb, (0, 0), mask_thumb)

    # Master shadow
    thumb_shadow = Image.new('RGBA', (440, 440), (0, 0, 0, 0))
    ImageDraw.Draw(thumb_shadow).rounded_rectangle([10, 15, 430, 435], radius=92, fill=(0, 0, 0, 160))
    thumb_shadow = thumb_shadow.filter(ImageFilter.GaussianBlur(18))
    showcase.paste(thumb_shadow, (90, 155), thumb_shadow)
    showcase.paste(rounded_thumb, (100, 165), rounded_thumb)

    # Badges underneath master
    features = [
        "- 3D Polished Solar-Gold Lightning",
        "- Glowing Electric-Cyan Neon Ring",
        "- Brushed Titanium Hexagonal Core",
        "- Deep Space Navy Energy Backdrop",
        "- 66% Android Adaptive Safe Zone",
    ]
    y_feat = 620
    for feat in features:
        draw.text((100, y_feat), feat, fill=(148, 163, 184, 255))
        y_feat += 32

    # Right Section: Android Phone Home Screen Mockup (600 to 1540)
    phone_w, phone_h = 420, 800
    px = 640
    py = 50

    # Phone outer frame
    draw.rounded_rectangle([px - 4, py - 4, px + phone_w + 4, py + phone_h + 4], radius=44, fill=(30, 41, 59, 255))
    draw.rounded_rectangle([px, py, px + phone_w, py + phone_h], radius=40, fill=(15, 23, 42, 255))

    # Phone wallpaper (ambient dark wallpaper with soft cyan gradient)
    for row in range(py, py + phone_h):
        t = (row - py) / phone_h
        wr = int(12 * (1 - t) + 8 * t)
        wg = int(24 * (1 - t) + 16 * t)
        wb = int(58 * (1 - t) + 38 * t)
        draw.line([(px, row), (px + phone_w, row)], fill=(wr, wg, wb, 255))

    # Phone Status Bar
    draw.text((px + 28, py + 18), "12:00", fill=(255, 255, 255, 220))
    draw.text((px + phone_w - 90, py + 18), "5G  100%", fill=(255, 255, 255, 220))

    # Phone Clock Widget
    draw.text((px + 120, py + 85), "12:00", fill=(255, 255, 255, 255))
    draw.text((px + 105, py + 135), "Thursday, 12 Nov", fill=(148, 163, 184, 255))

    # Grid of Apps on Home Screen
    # Row 1 of apps
    # App 1: Shree Shakti Electric (Circular / Pixel style)
    icon_s = 64
    c_icon = master.resize((icon_s, icon_s), Image.Resampling.LANCZOS)
    c_mask = Image.new('L', (icon_s, icon_s), 0)
    ImageDraw.Draw(c_mask).ellipse([0, 0, icon_s, icon_s], fill=255)
    c_app = Image.new('RGBA', (icon_s, icon_s), (0, 0, 0, 0))
    c_app.paste(c_icon, (0, 0), c_mask)

    # Shadow for icon
    app_shadow = Image.new('RGBA', (icon_s + 10, icon_s + 10), (0, 0, 0, 0))
    ImageDraw.Draw(app_shadow).ellipse([2, 5, icon_s + 6, icon_s + 9], fill=(0, 0, 0, 140))
    app_shadow = app_shadow.filter(ImageFilter.GaussianBlur(4))

    col1_x = px + 45
    col2_x = px + 140
    col3_x = px + 235
    col4_x = px + 330
    row1_y = py + 230

    # Shree Shakti Electric (Featured!)
    showcase.paste(app_shadow, (col1_x - 3, row1_y), app_shadow)
    showcase.paste(c_app, (col1_x, row1_y), c_app)
    draw.text((col1_x - 12, row1_y + 70), "Shree Shakti", fill=(255, 255, 255, 255))

    # Dummy Apps to show real home screen context
    dummy_colors = [
        ((37, 99, 235), "Chrome"),
        ((22, 163, 74), "WhatsApp"),
        ((220, 38, 38), "YouTube"),
    ]
    for idx, (col, name) in enumerate(dummy_colors):
        dx = [col2_x, col3_x, col4_x][idx]
        dummy_icon = Image.new('RGBA', (icon_s, icon_s), (0, 0, 0, 0))
        ImageDraw.Draw(dummy_icon).ellipse([0, 0, icon_s, icon_s], fill=col)
        showcase.paste(dummy_icon, (dx, row1_y), dummy_icon)
        draw.text((dx + 8, row1_y + 70), name, fill=(203, 213, 225, 255))

    # Row 2 of apps: Squircle Launcher Style (Samsung Galaxy / One UI)
    row2_y = py + 340
    sq_mask = Image.new('L', (icon_s, icon_s), 0)
    ImageDraw.Draw(sq_mask).rounded_rectangle([0, 0, icon_s, icon_s], radius=18, fill=255)
    sq_app = Image.new('RGBA', (icon_s, icon_s), (0, 0, 0, 0))
    sq_app.paste(c_icon, (0, 0), sq_mask)

    showcase.paste(sq_app, (col1_x, row2_y), sq_app)
    draw.text((col1_x - 15, row2_y + 70), "One UI Mask", fill=(148, 163, 184, 255))

    # Rounded Rect (MIUI / ColorOS)
    rr_mask = Image.new('L', (icon_s, icon_s), 0)
    ImageDraw.Draw(rr_mask).rounded_rectangle([0, 0, icon_s, icon_s], radius=14, fill=255)
    rr_app = Image.new('RGBA', (icon_s, icon_s), (0, 0, 0, 0))
    rr_app.paste(c_icon, (0, 0), rr_mask)

    showcase.paste(rr_app, (col2_x, row2_y), rr_app)
    draw.text((col2_x - 10, row2_y + 70), "Squircle", fill=(148, 163, 184, 255))

    # Density Comparison Bar on the Right (1100 to 1560)
    rx = 1120
    draw.rounded_rectangle([rx, 60, rx + 420, 840], radius=24, fill=(18, 24, 38, 255), outline=(56, 189, 248, 100), width=2)
    draw.text((rx + 30, 85), "DENSITY & RESOLUTION AUDIT", fill=(241, 245, 249, 255))
    draw.text((rx + 30, 110), "Legibility test at actual Android launcher scales", fill=(100, 116, 139, 255))

    density_test = [
        ("xxxhdpi : 192 x 192 px (48 x 48 dp @ 4x)", 192),
        ("xxhdpi  : 144 x 144 px (48 x 48 dp @ 3x)", 144),
        ("xhdpi   : 96 x 96 px   (48 x 48 dp @ 2x)", 96),
        ("hdpi    : 72 x 72 px   (48 x 48 dp @ 1.5x)", 72),
        ("mdpi    : 48 x 48 px   (48 x 48 dp @ 1x)", 48),
    ]

    dy_pos = 160
    for label, d_sz in density_test:
        draw.text((rx + 30, dy_pos), label, fill=(203, 213, 225, 255))
        d_img = master.resize((d_sz, d_sz), Image.Resampling.LANCZOS)
        # Circular mask for preview
        d_mask = Image.new('L', (d_sz, d_sz), 0)
        ImageDraw.Draw(d_mask).ellipse([0, 0, d_sz, d_sz], fill=255)
        d_clean = Image.new('RGBA', (d_sz, d_sz), (0, 0, 0, 0))
        d_clean.paste(d_img, (0, 0), d_mask)

        showcase.paste(d_clean, (rx + 30, dy_pos + 26), d_clean)
        dy_pos += d_sz + 45

    showcase.save(os.path.join(artifact_dir, 'app_icon_showcase.png'), 'PNG')
    print("Generated app_icon_showcase.png successfully!")

if __name__ == '__main__':
    generate_all_icons()
