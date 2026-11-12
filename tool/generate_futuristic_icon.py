import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops

def create_futuristic_icon():
    # Render at 2048x2048 supersampling for pristine antialiasing
    W, H = 2048, 2048
    CX, CY = W // 2, H // 2

    # =========================================================================
    # 1. BACKGROUND LAYER (Deep Space Navy with Electric Blue & Cyan Energy Core)
    # =========================================================================
    bg = Image.new('RGBA', (W, H), (0, 0, 0, 0))

    # Base radial gradient using numpy
    y, x = np.ogrid[:H, :W]
    dist_from_center = np.sqrt((x - CX)**2 + (y - CY)**2)
    max_dist = np.sqrt(CX**2 + CY**2)
    norm_dist = np.clip(dist_from_center / max_dist, 0.0, 1.0)

    # Core colors: Center #0B2559 -> Mid #051433 -> Outer #020714
    r_arr = (11 * (1 - norm_dist)**1.5 + 4 * norm_dist).astype(np.uint8)
    g_arr = (37 * (1 - norm_dist)**1.5 + 9 * norm_dist).astype(np.uint8)
    b_arr = (89 * (1 - norm_dist)**1.5 + 24 * norm_dist).astype(np.uint8)
    a_arr = np.full((H, W), 255, dtype=np.uint8)

    bg_np = np.stack([r_arr, g_arr, b_arr, a_arr], axis=-1)
    bg = Image.fromarray(bg_np, mode='RGBA')

    # Radial ambient energy glow from center
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glow)
    
    # Outer Electric Blue Aura
    g_draw.ellipse([CX - 750, CY - 750, CX + 750, CY + 750], fill=(0, 149, 255, 75))
    # Mid Cyan Energy Ring
    g_draw.ellipse([CX - 500, CY - 500, CX + 500, CY + 500], fill=(0, 229, 255, 60))
    # Golden Inner Fusion Spark
    g_draw.ellipse([CX - 280, CY - 280, CX + 280, CY + 280], fill=(255, 183, 3, 40))
    glow = glow.filter(ImageFilter.GaussianBlur(130))
    bg = Image.alpha_composite(bg, glow)

    # Subtle Futuristic Tech/Circuit Accents (within outer background)
    circuit = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    c_draw = ImageDraw.Draw(circuit)
    
    # Concentric energy rings
    c_draw.ellipse([CX - 780, CY - 780, CX + 780, CY + 780], outline=(0, 229, 255, 25), width=3)
    c_draw.ellipse([CX - 880, CY - 880, CX + 880, CY + 880], outline=(30, 64, 175, 30), width=4)
    
    # Orbital tick marks (12 radial points)
    for i in range(12):
        angle = i * (2 * math.pi / 12)
        r1 = 760
        r2 = 800
        x1 = CX + int(r1 * math.cos(angle))
        y1 = CY + int(r1 * math.sin(angle))
        x2 = CX + int(r2 * math.cos(angle))
        y2 = CY + int(r2 * math.sin(angle))
        c_draw.line([(x1, y1), (x2, y2)], fill=(0, 229, 255, 55), width=4)

    # 4 Cardinal Circuit Nodes
    for angle in [0, math.pi/2, math.pi, 3*math.pi/2]:
        nx = CX + int(880 * math.cos(angle))
        ny = CY + int(880 * math.sin(angle))
        c_draw.ellipse([nx - 12, ny - 12, nx + 12, ny + 12], fill=(0, 229, 255, 120))

    circuit = circuit.filter(ImageFilter.GaussianBlur(1.5))
    bg = Image.alpha_composite(bg, circuit)

    # =========================================================================
    # 2. FOREGROUND LAYER (Futuristic Geometric Shield + 3D Golden Lightning)
    # =========================================================================
    fg = Image.new('RGBA', (W, H), (0, 0, 0, 0))

    # All foreground elements must be safely within radius 620 px (safe zone)
    # The Shield is an elegant, faceted hexagonal tech crest / billing document shield.
    # Dimensions: width = 640, height = 800 (centered at CX, CY)
    sw = 600
    sh = 760
    
    # Polygon points for a chamfered high-tech shield with a subtle folded top-right corner
    # (Harmonizing electrical shield + official invoice document)
    fold_size = 90
    shield_pts = [
        (CX - sw // 2, CY - sh // 2 + 60),      # Top left chamfer start
        (CX - sw // 2 + 60, CY - sh // 2),      # Top left chamfer end
        (CX + sw // 2 - fold_size, CY - sh // 2),# Top right fold start
        (CX + sw // 2, CY - sh // 2 + fold_size),# Top right fold end
        (CX + sw // 2, CY + sh // 2 - 180),     # Right edge
        (CX, CY + sh // 2),                     # Bottom crest point
        (CX - sw // 2, CY + sh // 2 - 180),     # Left edge
    ]

    # --- 2A. Shield Drop Shadow onto Background ---
    shield_shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shield_shadow)
    # Offset shadow down-right
    shadow_pts = [(x + 12, y + 28) for x, y in shield_pts]
    s_draw.polygon(shadow_pts, fill=(0, 0, 0, 160))
    shield_shadow = shield_shadow.filter(ImageFilter.GaussianBlur(38))
    fg = Image.alpha_composite(fg, shield_shadow)

    # --- 2B. Outer Shield Metallic Bevel / Rim ---
    shield_rim = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    sr_draw = ImageDraw.Draw(shield_rim)
    # Solid metallic base
    sr_draw.polygon(shield_pts, fill=(15, 30, 65, 255))
    # Gradient overlay for metallic rim
    rim_grad = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    rg_draw = ImageDraw.Draw(rim_grad)
    for y_pos in range(CY - sh // 2, CY + sh // 2 + 10):
        t = (y_pos - (CY - sh // 2)) / sh
        # Top electric blue to bottom dark navy
        rc = int(37 * (1 - t) + 10 * t)
        gc = int(99 * (1 - t) + 25 * t)
        bc = int(235 * (1 - t) + 80 * t)
        rg_draw.line([(CX - sw // 2 - 20, y_pos), (CX + sw // 2 + 20, y_pos)], fill=(rc, gc, bc, 255), width=1)
    
    shield_rim = ImageChops.multiply(shield_rim, rim_grad)
    fg = Image.alpha_composite(fg, shield_rim)

    # --- 2C. Inner Shield Body (Frosted Glassmorphic Dark Blue) ---
    inset = 18
    inner_pts = [
        (CX - sw // 2 + inset, CY - sh // 2 + 60),
        (CX - sw // 2 + 60, CY - sh // 2 + inset),
        (CX + sw // 2 - fold_size + inset // 2, CY - sh // 2 + inset),
        (CX + sw // 2 - inset, CY - sh // 2 + fold_size - inset // 2),
        (CX + sw // 2 - inset, CY + sh // 2 - 180 - inset),
        (CX, CY + sh // 2 - inset),
        (CX - sw // 2 + inset, CY + sh // 2 - 180 - inset),
    ]

    shield_inner = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    si_draw = ImageDraw.Draw(shield_inner)
    si_draw.polygon(inner_pts, fill=(8, 22, 50, 245))

    # Top-Left Specular Sheen across the shield
    sheen = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    sh_draw = ImageDraw.Draw(sheen)
    # Diagonal highlight
    sheen_pts = [
        (CX - sw // 2 + inset, CY - sh // 2 + 60),
        (CX + sw // 2 - fold_size, CY - sh // 2 + inset),
        (CX - sw // 2 + inset, CY + 50),
    ]
    sh_draw.polygon(sheen_pts, fill=(255, 255, 255, 22))
    sheen = sheen.filter(ImageFilter.GaussianBlur(12))
    shield_inner = Image.alpha_composite(shield_inner, sheen)

    # Folded Corner Accent (Top Right)
    fold_pts = [
        (CX + sw // 2 - fold_size, CY - sh // 2),
        (CX + sw // 2, CY - sh // 2 + fold_size),
        (CX + sw // 2 - fold_size, CY - sh // 2 + fold_size),
    ]
    si_draw.polygon(fold_pts, fill=(30, 58, 138, 255), outline=(56, 189, 248, 200))
    
    # Futuristic etched ledger lines on shield body (representing billing & calculation)
    line_y_starts = [CY - 160, CY - 100, CY - 40, CY + 20, CY + 80]
    for ly in line_y_starts:
        # Subtle horizontal circuit lines behind lightning
        si_draw.line([(CX - 190, ly), (CX - 70, ly)], fill=(56, 189, 248, 60), width=4)
        si_draw.line([(CX + 70, ly), (CX + 190, ly)], fill=(56, 189, 248, 60), width=4)
        # Small node dots at ends
        si_draw.ellipse([CX - 194, ly - 4, CX - 186, ly + 4], fill=(0, 229, 255, 90))
        si_draw.ellipse([CX + 186, ly - 4, CX + 194, ly + 4], fill=(0, 229, 255, 90))

    # Outer Neon Border for Inner Shield
    si_draw.polygon(inner_pts, outline=(56, 189, 248, 160), width=3)
    fg = Image.alpha_composite(fg, shield_inner)

    # --- 2D. 3D GOLDEN LIGHTNING BOLT (The Hero Element) ---
    # The lightning bolt is designed with faceted 3D geometry:
    # A central ridge divides the illuminated left facet from the shaded right facet.
    
    # Key anchor points for the lightning bolt:
    # Top strike: (CX + 35, CY - 310)
    # Top outer left corner: (CX - 140, CY - 110)
    # Inner left crook: (CX - 25, CY - 100)
    # Mid outer left corner: (CX - 180, CY + 90)
    # Mid inner left crook: (CX - 20, CY + 100)
    # Bottom tip: (CX + 10, CY + 330)
    # Inner right crook 2: (CX + 55, CY + 120)
    # Mid outer right corner: (CX + 160, CY + 110)
    # Inner right crook 1: (CX + 50, CY - 80)
    # Top outer right corner: (CX + 170, CY - 90)

    # Left Facet (Light side: radiant golden yellow to amber)
    bolt_left_pts = [
        (CX + 25, CY - 310),   # Top point
        (CX - 145, CY - 105),  # Left point 1
        (CX - 30, CY - 95),    # Inner nook 1
        (CX - 185, CY + 95),   # Left point 2
        (CX - 25, CY + 105),   # Inner nook 2
        (CX + 10, CY + 330),   # Bottom tip
        # Spine running back up the center
        (CX + 15, CY + 100),   # Spine mid 2
        (CX - 85, CY + 95),    # Spine left mid
        (CX + 10, CY - 100),   # Spine mid 1
        (CX - 65, CY - 105),   # Spine top left
    ]

    # Full Lightning Polygon for Ambient Glow & Drop Shadow
    bolt_full_pts = [
        (CX + 25, CY - 310),   # Top point
        (CX - 145, CY - 105),  # Left point 1
        (CX - 30, CY - 95),    # Inner nook 1
        (CX - 185, CY + 95),   # Left point 2
        (CX - 25, CY + 105),   # Inner nook 2
        (CX + 10, CY + 330),   # Bottom tip
        (CX + 55, CY + 125),   # Right inner nook 2
        (CX + 170, CY + 115),  # Right point 2
        (CX + 50, CY - 75),    # Right inner nook 1
        (CX + 175, CY - 85),   # Right point 1
    ]

    # Bolt Drop Shadow onto Shield
    bolt_shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    bs_draw = ImageDraw.Draw(bolt_shadow)
    bs_pts = [(x + 10, y + 18) for x, y in bolt_full_pts]
    bs_draw.polygon(bs_pts, fill=(0, 0, 0, 180))
    bolt_shadow = bolt_shadow.filter(ImageFilter.GaussianBlur(22))
    fg = Image.alpha_composite(fg, bolt_shadow)

    # Bolt Radiant Golden / Cyan Ambient Corona Glow
    bolt_corona = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    bc_draw = ImageDraw.Draw(bolt_corona)
    bc_draw.polygon(bolt_full_pts, fill=(245, 158, 11, 160))
    bolt_corona = bolt_corona.filter(ImageFilter.GaussianBlur(35))
    fg = Image.alpha_composite(fg, bolt_corona)

    # Intense Inner Core Glow
    bolt_core_glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    bcg_draw = ImageDraw.Draw(bolt_core_glow)
    bcg_draw.polygon(bolt_full_pts, fill=(255, 230, 0, 190))
    bolt_core_glow = bolt_core_glow.filter(ImageFilter.GaussianBlur(15))
    fg = Image.alpha_composite(fg, bolt_core_glow)

    # Right Facet (Shaded side: deep golden amber to rich orange)
    # We construct the 3D facets cleanly:
    bolt_3d = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    b3_draw = ImageDraw.Draw(bolt_3d)

    # Base solid bolt in golden amber
    b3_draw.polygon(bolt_full_pts, fill=(217, 119, 6, 255))

    # Upper segment left facet (Bright Solar Yellow)
    facet_tl = [
        (CX + 25, CY - 310),
        (CX - 145, CY - 105),
        (CX - 30, CY - 95),
        (CX + 35, CY - 95),
    ]
    b3_draw.polygon(facet_tl, fill=(254, 240, 138, 255))

    # Upper segment right facet (Golden Orange)
    facet_tr = [
        (CX + 25, CY - 310),
        (CX + 35, CY - 95),
        (CX + 50, CY - 75),
        (CX + 175, CY - 85),
    ]
    b3_draw.polygon(facet_tr, fill=(245, 158, 11, 255))

    # Mid segment left facet (Bright Yellow-Gold)
    facet_ml = [
        (CX - 30, CY - 95),
        (CX - 185, CY + 95),
        (CX - 25, CY + 105),
        (CX + 40, CY + 105),
    ]
    b3_draw.polygon(facet_ml, fill=(253, 224, 71, 255))

    # Mid segment right facet (Rich Amber)
    facet_mr = [
        (CX + 50, CY - 75),
        (CX + 170, CY + 115),
        (CX + 55, CY + 125),
        (CX + 40, CY + 105),
    ]
    b3_draw.polygon(facet_mr, fill=(217, 119, 6, 255))

    # Bottom segment left facet (Brilliant Gold)
    facet_bl = [
        (CX - 25, CY + 105),
        (CX + 10, CY + 330),
        (CX + 25, CY + 125),
    ]
    b3_draw.polygon(facet_bl, fill=(250, 204, 21, 255))

    # Bottom segment right facet (Deep Amber Shadow)
    facet_br = [
        (CX + 55, CY + 125),
        (CX + 10, CY + 330),
        (CX + 25, CY + 125),
    ]
    b3_draw.polygon(facet_br, fill=(180, 83, 9, 255))

    # Specular White Spine & Crest Highlight Line
    spine_pts = [
        (CX + 25, CY - 310),
        (CX + 35, CY - 95),
        (CX - 30, CY - 95),
        (CX + 40, CY + 105),
        (CX - 25, CY + 105),
        (CX + 10, CY + 330),
    ]
    for i in range(len(spine_pts) - 1):
        b3_draw.line([spine_pts[i], spine_pts[i+1]], fill=(255, 255, 255, 230), width=4)

    # Pure White Hot Core Sparks at tips
    b3_draw.ellipse([CX + 21, CY - 314, CX + 29, CY - 306], fill=(255, 255, 255, 255))
    b3_draw.ellipse([CX + 6, CY + 326, CX + 14, CY + 334], fill=(255, 255, 255, 255))

    # Outer crisp rim of the lightning bolt
    b3_draw.polygon(bolt_full_pts, outline=(255, 251, 235, 180), width=2)
    fg = Image.alpha_composite(fg, bolt_3d)

    # --- 2E. Electric Cyan Energy Flares (Subtle Electric Arcs) ---
    flare = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    fl_draw = ImageDraw.Draw(flare)
    # Electric energy spark near top tip
    fl_draw.line([(CX + 25, CY - 310), (CX + 70, CY - 350)], fill=(0, 229, 255, 180), width=4)
    fl_draw.line([(CX + 70, CY - 350), (CX + 95, CY - 340)], fill=(0, 229, 255, 140), width=3)
    # Electric energy spark near mid crook
    fl_draw.line([(CX - 185, CY + 95), (CX - 225, CY + 80)], fill=(0, 229, 255, 160), width=3)
    # Electric spark near bottom tip
    fl_draw.line([(CX + 10, CY + 330), (CX - 25, CY + 365)], fill=(0, 229, 255, 170), width=3)

    flare = flare.filter(ImageFilter.GaussianBlur(2.5))
    fg = Image.alpha_composite(fg, flare)

    # =========================================================================
    # 3. COMBINED MASTER ICON
    # =========================================================================
    master = Image.alpha_composite(bg, fg)

    # Overall Subtle Lens Reflection Sheen across the entire upper-left
    lens_sheen = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ls_draw = ImageDraw.Draw(lens_sheen)
    # Elliptical curved gloss curve
    ls_draw.ellipse([-W // 4, -H // 2, W + W // 4, H // 2 + 100], fill=(255, 255, 255, 18))
    lens_sheen = lens_sheen.filter(ImageFilter.GaussianBlur(25))
    master = Image.alpha_composite(master, lens_sheen)

    # Downsample from 2048x2048 to 1024x1024 with LANCZOS for razor-sharp vector quality
    master_1024 = master.resize((1024, 1024), Image.Resampling.LANCZOS)
    fg_1024 = fg.resize((1024, 1024), Image.Resampling.LANCZOS)
    bg_1024 = bg.resize((1024, 1024), Image.Resampling.LANCZOS)

    # Ensure directories
    os.makedirs('assets/icons', exist_ok=True)
    artifact_dir = r'C:/Users/Admin/.gemini/antigravity/brain/984986f9-e387-41a0-9ff9-9ba97a78e1bf'
    os.makedirs(artifact_dir, exist_ok=True)

    # Save Master Assets
    master_1024.save('assets/icons/app_icon.png', 'PNG')
    fg_1024.save('assets/icons/app_icon_foreground.png', 'PNG')
    bg_1024.save('assets/icons/app_icon_background.png', 'PNG')

    master_1024.save(os.path.join(artifact_dir, 'app_icon_master_1024.png'), 'PNG')
    fg_1024.save(os.path.join(artifact_dir, 'app_icon_foreground_1024.png'), 'PNG')
    bg_1024.save(os.path.join(artifact_dir, 'app_icon_background_1024.png'), 'PNG')

    print("Master 1024x1024 icon assets created successfully!")
    return master_1024, fg_1024, bg_1024

if __name__ == '__main__':
    create_futuristic_icon()
