import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

def test_dynamic_bolt():
    W, H = 2048, 2048
    CX, CY = W // 2, H // 2

    # Canvas
    im = Image.new('RGBA', (W, H), (10, 22, 50, 255))
    draw = ImageDraw.Draw(im)

    # 1. Background radial energy glow
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glow)
    g_draw.ellipse([CX - 700, CY - 700, CX + 700, CY + 700], fill=(0, 150, 255, 80))
    g_draw.ellipse([CX - 400, CY - 400, CX + 400, CY + 400], fill=(0, 229, 255, 60))
    glow = glow.filter(ImageFilter.GaussianBlur(120))
    im = Image.alpha_composite(im, glow)

    # 2. Sleek Hexagonal Power Crest / Shield
    # Hexagon with chamfered bevels
    hw = 640
    hh = 780
    shield_pts = [
        (CX - hw // 2 + 80, CY - hh // 2),        # Top chamfer left
        (CX + hw // 2 - 80, CY - hh // 2),        # Top chamfer right
        (CX + hw // 2, CY - hh // 2 + 180),       # Upper right
        (CX + hw // 2, CY + hh // 2 - 220),       # Lower right
        (CX, CY + hh // 2),                       # Bottom point
        (CX - hw // 2, CY + hh // 2 - 220),       # Lower left
        (CX - hw // 2, CY - hh // 2 + 180),       # Upper left
    ]

    # Shield shadow
    s_shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ss_draw = ImageDraw.Draw(s_shadow)
    ss_draw.polygon([(x + 15, y + 30) for x, y in shield_pts], fill=(0, 0, 0, 180))
    s_shadow = s_shadow.filter(ImageFilter.GaussianBlur(40))
    im = Image.alpha_composite(im, s_shadow)

    # Metallic titanium border
    s_rim = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    sr_draw = ImageDraw.Draw(s_rim)
    sr_draw.polygon(shield_pts, fill=(18, 38, 82, 255), outline=(56, 189, 248, 220))
    im = Image.alpha_composite(im, s_rim)

    # Inner glass body (inset 22px)
    inner_pts = [
        (CX - hw // 2 + 95, CY - hh // 2 + 22),
        (CX + hw // 2 - 95, CY - hh // 2 + 22),
        (CX + hw // 2 - 22, CY - hh // 2 + 185),
        (CX + hw // 2 - 22, CY + hh // 2 - 225),
        (CX, CY + hh // 2 - 26),
        (CX - hw // 2 + 22, CY + hh // 2 - 225),
        (CX - hw // 2 + 22, CY - hh // 2 + 185),
    ]
    s_body = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    sb_draw = ImageDraw.Draw(s_body)
    sb_draw.polygon(inner_pts, fill=(6, 18, 42, 245), outline=(14, 165, 233, 140))
    
    # Etched tech lines
    for ly in [CY - 160, CY - 80, CY, CY + 80, CY + 160]:
        sb_draw.line([(CX - 220, ly), (CX - 80, ly)], fill=(56, 189, 248, 50), width=4)
        sb_draw.line([(CX + 80, ly), (CX + 220, ly)], fill=(56, 189, 248, 50), width=4)
        sb_draw.ellipse([CX - 224, ly - 4, CX - 216, ly + 4], fill=(0, 229, 255, 80))
        sb_draw.ellipse([CX + 216, ly - 4, CX + 224, ly + 4], fill=(0, 229, 255, 80))

    im = Image.alpha_composite(im, s_body)

    # 3. Dynamic Diagonal Electric Lightning Bolt (3D Faceted)
    # The classic high-voltage dynamic bolt:
    # Top start: CX + 100, CY - 320
    # Left jog 1: CX - 130, CY - 20
    # Right jog 1: CX + 20, CY - 10
    # Left jog 2: CX - 180, CY + 140
    # Right jog 2: CX - 20, CY + 150
    # Spear tip: CX + 80, CY + 330 (or reversed)
    # Let's use standard strike: top-right to bottom-left spear, or top-left to bottom-right!
    # A downward plunge towards bottom-left gives tremendous energy:
    p_top = (CX + 80, CY - 310)         # Top acute point
    p_right_edge = (CX + 140, CY - 290) # Top right bevel
    p_mid_right_in = (CX + 20, CY - 30) # Upper right nook
    p_mid_right_out = (CX + 160, CY - 10)# Mid right wing
    p_bottom_spear = (CX - 70, CY + 340)# Bottom spear tip
    p_mid_left_in = (CX - 10, CY + 60)  # Lower left nook
    p_mid_left_out = (CX - 160, CY + 40)# Mid left wing
    p_upper_left_in = (CX - 40, CY - 160)# Upper left nook
    p_upper_left_out = (CX - 120, CY - 180)# Upper left wing

    # Full polygon
    bolt_polygon = [
        p_top,
        p_right_edge,
        p_mid_right_in,
        p_mid_right_out,
        p_bottom_spear,
        p_mid_left_in,
        p_mid_left_out,
        p_upper_left_in,
        p_upper_left_out,
    ]

    # Bolt Drop Shadow
    b_shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    bsh_draw = ImageDraw.Draw(b_shadow)
    bsh_draw.polygon([(x + 12, y + 24) for x, y in bolt_polygon], fill=(0, 0, 0, 190))
    b_shadow = b_shadow.filter(ImageFilter.GaussianBlur(25))
    im = Image.alpha_composite(im, b_shadow)

    # Bolt Radiant Golden / Solar Aura
    b_aura = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ba_draw = ImageDraw.Draw(b_aura)
    ba_draw.polygon(bolt_polygon, fill=(245, 158, 11, 180))
    b_aura = b_aura.filter(ImageFilter.GaussianBlur(30))
    im = Image.alpha_composite(im, b_aura)

    # Core Intense Glow
    b_core = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    bc_draw = ImageDraw.Draw(b_core)
    bc_draw.polygon(bolt_polygon, fill=(255, 234, 0, 220))
    b_core = b_core.filter(ImageFilter.GaussianBlur(12))
    im = Image.alpha_composite(im, b_core)

    # 3D Facets (Left illuminated facet vs Right shaded facet)
    # Center spine running through the bolt
    s1 = p_top
    s2 = (CX - 10, CY - 120)
    s3 = (CX + 40, CY - 10)
    s4 = (CX - 60, CY + 100)
    s5 = p_bottom_spear

    b_solid = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    bs_draw = ImageDraw.Draw(b_solid)

    # Facet 1 (Top Left): Bright Solar Yellow #FEF08A
    bs_draw.polygon([p_top, p_upper_left_out, p_upper_left_in, s2], fill=(254, 240, 138, 255))
    # Facet 2 (Top Right): Golden Amber #F59E0B
    bs_draw.polygon([p_top, s2, p_mid_right_in, p_right_edge], fill=(245, 158, 11, 255))

    # Facet 3 (Mid Left): Radiant Gold #FACC15
    bs_draw.polygon([s2, p_upper_left_in, p_mid_left_out, p_mid_left_in, s4], fill=(250, 204, 21, 255))
    # Facet 4 (Mid Right): Warm Amber #D97706
    bs_draw.polygon([s2, s3, p_mid_right_out, p_mid_right_in], fill=(217, 119, 6, 255))
    bs_draw.polygon([s3, s4, p_mid_left_in, (CX + 50, CY + 40)], fill=(245, 158, 11, 255))

    # Facet 5 (Bottom Spear Left): Brilliant Gold #FDE047
    bs_draw.polygon([s4, p_mid_left_in, p_bottom_spear], fill=(253, 224, 71, 255))
    # Facet 6 (Bottom Spear Right): Deep Golden Amber #B45309
    bs_draw.polygon([s4, (CX + 50, CY + 40), (CX + 20, CY + 160), p_bottom_spear], fill=(180, 83, 9, 255))

    # Spine Specular White Highlight
    spine = [s1, s2, s3, s4, s5]
    for i in range(len(spine) - 1):
        bs_draw.line([spine[i], spine[i+1]], fill=(255, 255, 255, 240), width=5)

    # Outer Edge Crisp Highlight
    bs_draw.polygon(bolt_polygon, outline=(255, 251, 235, 200), width=3)
    im = Image.alpha_composite(im, b_solid)

    # Electric Cyan Arcs / Flares at extremities
    arcs = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    a_draw = ImageDraw.Draw(arcs)
    a_draw.line([p_top, (p_top[0] + 50, p_top[1] - 40)], fill=(0, 229, 255, 200), width=4)
    a_draw.line([p_mid_right_out, (p_mid_right_out[0] + 50, p_mid_right_out[1] - 30)], fill=(0, 229, 255, 180), width=3)
    a_draw.line([p_bottom_spear, (p_bottom_spear[0] - 40, p_bottom_spear[1] + 40)], fill=(0, 229, 255, 200), width=4)
    arcs = arcs.filter(ImageFilter.GaussianBlur(2))
    im = Image.alpha_composite(im, arcs)

    # Downsample
    out = im.resize((1024, 1024), Image.Resampling.LANCZOS)
    out.save('C:/Users/Admin/.gemini/antigravity/brain/984986f9-e387-41a0-9ff9-9ba97a78e1bf/test_dynamic_bolt.png')
    print("Saved test_dynamic_bolt.png")

if __name__ == '__main__':
    test_dynamic_bolt()
