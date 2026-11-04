from PIL import Image, ImageDraw, ImageFont
import math
from pathlib import Path
root=Path('Native/Design')
out=root/'AppStore/zh-Hant/iPhone'
logo=Image.open('Native/FlagMaster/Assets.xcassets/AppIcon.appiconset/AppIcon.png')
font_dir=Path.home()/'Library'/'Fonts'
zh=str(font_dir/'ChironGoRoundTC-Medium.ttf')
title_font=str(font_dir/'ChironGoRoundTC-Black.ttf')
hand_font=str(font_dir/'JasonHandwriting6.ttf')
mono='/System/Library/Fonts/Menlo.ttc'
def f(path,n): return ImageFont.truetype(path,n)
def mask(size,r):
    m=Image.new('L',size)
    ImageDraw.Draw(m).rounded_rectangle((0,0,size[0]-1,size[1]-1),r,fill=255)
    return m
data=[
('home','START','認識世界','從一面旗開始','選擇玩法，開始你的國旗挑戰。'),
('game','QUIZ','這面旗幟','是哪一國？','從四個選項找出正確答案。'),
('answer','REVEAL','答完一題','認識一個國家','看答案與國旗小知識，再挑戰下一題。'),
('journeys','EXPLORE','挑一個地區','開始國旗探險','六個地區，各有不同的國旗等你辨認。'),
('records','COLLECT','你的國旗圖鑑','還差幾面？','追蹤收集進度，找到還沒記熟的國旗。'),
('results','RESULTS','回合結束','錯題再挑戰','查看答對率，再練習這一輪猜錯的國旗。'),
('pause','PAUSE','暫停一下','準備好再繼續','回到原本的題目，或重新開始一輪。'),
]


from PIL import ImageFilter
W,H=1206,2622
expected={f"{i:02d}-{row[0]}.png" for i,row in enumerate(data,1)}
for old in out.glob("*.png"):
    if old.name not in expected:
        old.unlink()
labels=['開始探索','國旗挑戰','學一點新知','六大地區','收集圖鑑','錯題再練','隨時繼續']

def star(draw,x,y,r,color):
    draw.polygon([(x,y-r),(x+r*.23,y-r*.23),(x+r,y),(x+r*.23,y+r*.23),(x,y+r),(x-r*.23,y+r*.23),(x-r,y),(x-r*.23,y-r*.23)],fill=color)

def sticker(canvas,kind,center,angle=0):
    card=Image.new('RGBA',(190,144))
    d=ImageDraw.Draw(card)
    d.rounded_rectangle((8,8,182,136),24,fill='white',outline='#E3E5E1',width=2)
    ink='#174550'; coral='#DE624A'; gold='#E4AB38'
    flag=Path('Native/FlagMaster/Resources/Flags')/f'{kind}.png'
    if flag.exists():
        pic=Image.open(flag).convert('RGBA')
        pic.thumbnail((133,88),Image.Resampling.LANCZOS)
        card.alpha_composite(pic,((190-pic.width)//2,(144-pic.height)//2))
    elif kind=='globe':
        d.ellipse((48,25,142,119),outline=ink,width=5)
        d.ellipse((73,25,117,119),outline=ink,width=4)
        d.arc((48,43,142,96),0,360,fill=ink,width=3)
        d.line((48,72,142,72),fill=ink,width=3)
    elif kind=='check':
        d.ellipse((50,27,140,117),fill='#D6EBDB')
        d.line([(71,73),(89,91),(121,53)],fill=ink,width=10,joint='curve')
    elif kind=='trophy':
        d.polygon([(62,29),(129,29),(120,78),(96,95),(72,78)],fill=gold)
        d.arc((40,34,84,79),70,275,fill=gold,width=8)
        d.arc((108,34,152,79),-95,110,fill=gold,width=8)
        d.line((96,88,96,110),fill=ink,width=6)
        d.rounded_rectangle((69,107,123,117),4,fill=ink)
    elif kind=='pause':
        d.rounded_rectangle((66,39,85,107),7,fill=coral)
        d.rounded_rectangle((107,39,126,107),7,fill=coral)
    elif kind=='pin':
        d.ellipse((62,26,130,94),fill=coral)
        d.polygon([(68,77),(124,77),(96,119)],fill=coral)
        d.ellipse((82,45,110,73),fill='white')
    elif kind=='cards':
        for offset in (0,12,24):
            d.rounded_rectangle((54+offset,30+offset,117+offset,88+offset),8,fill='#F1DCA4',outline=ink,width=3)
        star(d,109,80,17,coral)
    else:
        d.text((95,70),'?',font=f(zh,80),fill=coral,anchor='mm',stroke_width=2)
    card=card.rotate(angle,expand=True,resample=Image.Resampling.BICUBIC)
    x=int(center[0]-card.width/2); y=int(center[1]-card.height/2)
    layer=Image.new('RGBA',canvas.size)
    layer.paste((14,39,43,35),(x,y+13,x+card.width,y+13+card.height),card.getchannel('A'))
    canvas=Image.alpha_composite(canvas,layer.filter(ImageFilter.GaussianBlur(13)))
    canvas.alpha_composite(card,(x,y))
    return canvas

themes={
'home':['JP','globe','BR'],
'game':['FR','question','CA'],
'answer':['question','check','globe'],
'journeys':['globe','pin','JP'],
'records':['JP','cards','FR'],
'results':['check','trophy','check'],
'pause':['globe','pause','pin'],
}

# Width, centre and rotation vary while the screenshot always scales uniformly.
layouts={
    'home':    (870, (650,1750), -9,  False, '#F5F5F3'),
    'game':    (980, (555,650),   13, True,  '#EDF4EF'),
    'answer':  (1020,(755,1940), -12, False, '#FBF1E5'),
    'journeys':(920, (500,640),  -13, True,  '#F3F5F3'),
    'records': (900, (740,1810),   8, False, '#F7EEEA'),
    'results': (790, (610,845),   -6, True,  '#F7F2DF'),
    'pause':   (850, (540,1810),   7, False, '#ECF3EF'),
}

def place_phone(canvas,shot,width,center,angle):
    height=round(shot.height*width/shot.width)
    shot=shot.resize((width,height),Image.Resampling.LANCZOS)
    border=24
    phone=Image.new('RGBA',(width+border*2,height+border*2))
    d=ImageDraw.Draw(phone)
    d.rounded_rectangle((0,0,phone.width-1,phone.height-1),97,fill='#151919',outline='#787E7B',width=5)
    phone.paste(shot,(border,border),mask(shot.size,74))
    phone=phone.rotate(angle,expand=True,resample=Image.Resampling.BICUBIC)
    x=round(center[0]-phone.width/2)
    y=round(center[1]-phone.height/2)
    shadow=Image.new('RGBA',canvas.size)
    shadow.paste((0,0,0,75),(x+8,y+24,x+8+phone.width,y+24+phone.height),phone.getchannel('A'))
    canvas=Image.alpha_composite(canvas,shadow.filter(ImageFilter.GaussianBlur(28)))
    canvas.alpha_composite(phone,(x,y))
    return canvas

for i,(source,mode,t1,t2,subtitle) in enumerate(data,1):
    width,center,angle,reverse,bg=layouts[source]
    im=Image.new('RGBA',(W,H),bg)
    d=ImageDraw.Draw(im)
    d.ellipse((-360,850,1510,2750),fill='#E6EAE4' if i%2 else '#E2EAE3')
    d.arc((-300,910,1500,2710),190,340,fill='#C7D6CE',width=4)
    for x,y in [(66,900),(1138,1250),(75,2150),(1080,2400)]:
        star(d,x,y,17,'#DDB468')
    shot=Image.open(root/'Previews'/'iPhone17Pro'/f'{source}.png').convert('RGB')
    if shot.size != (1206,2622):
        raise ValueError('Every preview requires a native 1206 x 2622 iPhone 17 Pro screenshot.')
    im=place_phone(im,shot,width,center,angle)

    ty=1950 if reverse else 140
    d=ImageDraw.Draw(im)
    # Left-aligned headlines keep an intentional edge beside the angled device.
    heading=Image.new('RGBA',(1080,304))
    hd=ImageDraw.Draw(heading)
    hd.text((12,12),t1,font=f(title_font,112),fill='#111515',anchor='lt')
    hd.text((12,151),t2,font=f(title_font,118),fill='#75827C',anchor='lt')
    heading=heading.rotate(1.5 if i%2 else -1.5,expand=True,resample=Image.Resampling.BICUBIC)
    im.alpha_composite(heading,(64,ty-12))
    d=ImageDraw.Draw(im)
    d.text((80,ty+470),subtitle,font=f(zh,38),fill='#434B4D',anchor='lm')
    badge=Image.new('RGBA',(500,120))
    bd=ImageDraw.Draw(badge)
    bd.rounded_rectangle((0,0,499,119),30,fill='white')
    bd.ellipse((24,36,72,84),fill='#DC4E3D')
    bd.text((102,60),labels[i-1],font=f(hand_font,57),fill='#171C1D',anchor='lm',stroke_width=1)
    badge=badge.rotate(5 if i%2 else -4,expand=True,resample=Image.Resampling.BICUBIC)
    im.alpha_composite(badge,(80,ty+292))

    # Each scene gets a different arrangement of relevant floating cards.
    spots={
        'home':[(945,530),(160,820),(1050,2210)],
        'game':[(145,1860),(1010,1500),(1010,2310)],
        'answer':[(940,530),(125,1100),(1070,2160)],
        'journeys':[(980,1680),(170,1840),(1025,2300)],
        'records':[(960,540),(125,950),(1060,2320)],
        'results':[(115,500),(1020,1660),(1010,2290)],
        'pause':[(960,540),(1060,1180),(140,2300)],
    }
    for kind,point,rotation in zip(themes[source],spots[source],(-14,9,17)):
        im=sticker(im,kind,point,rotation)
    im.convert('RGB').save(out/f'{i:02d}-{source}.png',optimize=True)
