"""
Script para generar el ícono de la app TranspoGestión CL
Ejecutar: python generar_icono.py
"""

from PIL import Image, ImageDraw, ImageFont
import os

def crear_icono_principal():
    """Crea el ícono principal de 1024x1024"""
    # Crear imagen con fondo azul
    size = 1024
    img = Image.new('RGB', (size, size), color='#1976D2')
    draw = ImageDraw.Draw(img)
    
    # Dibujar un camión/bus estilizado
    # Fondo del vehículo (rectángulo principal)
    vehicle_color = '#FFFFFF'
    draw.rectangle([200, 350, 824, 650], fill=vehicle_color, outline='#0D47A1', width=8)
    
    # Cabina del vehículo
    draw.rectangle([200, 350, 400, 650], fill='#E3F2FD', outline='#0D47A1', width=8)
    
    # Ventanas
    draw.rectangle([220, 380, 360, 480], fill='#64B5F6', outline='#0D47A1', width=4)
    draw.rectangle([430, 380, 570, 550], fill='#64B5F6', outline='#0D47A1', width=4)
    draw.rectangle([600, 380, 740, 550], fill='#64B5F6', outline='#0D47A1', width=4)
    
    # Ruedas (círculos negros)
    wheel_y = 650
    # Rueda delantera
    draw.ellipse([250, wheel_y-40, 350, wheel_y+60], fill='#212121', outline='#000000', width=6)
    draw.ellipse([280, wheel_y-10, 320, wheel_y+30], fill='#424242')
    
    # Rueda trasera
    draw.ellipse([674, wheel_y-40, 774, wheel_y+60], fill='#212121', outline='#000000', width=6)
    draw.ellipse([704, wheel_y-10, 744, wheel_y+30], fill='#424242')
    
    # Parrilla delantera
    for i in range(5):
        x = 220 + (i * 30)
        draw.line([x, 500, x, 630], fill='#0D47A1', width=3)
    
    # Guardar
    img.save('assets/app_icon.png')
    print('✅ Ícono principal creado: assets/app_icon.png')
    
    return img

def crear_icono_foreground():
    """Crea el ícono foreground para Android adaptive icon"""
    # Crear imagen transparente
    size = 1024
    img = Image.new('RGBA', (size, size), color=(0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Dibujar un camión más simple y centrado
    vehicle_color = '#FFFFFF'
    
    # Cuerpo principal
    draw.rectangle([250, 400, 774, 600], fill=vehicle_color, outline='#0D47A1', width=10)
    
    # Cabina
    draw.rectangle([250, 400, 400, 600], fill='#E3F2FD', outline='#0D47A1', width=10)
    
    # Ventanas
    draw.rectangle([280, 430, 360, 520], fill='#1976D2', outline='#0D47A1', width=6)
    draw.rectangle([450, 430, 600, 570], fill='#1976D2', outline='#0D47A1', width=6)
    draw.rectangle([630, 430, 744, 570], fill='#1976D2', outline='#0D47A1', width=6)
    
    # Ruedas
    wheel_y = 600
    # Rueda delantera
    draw.ellipse([290, wheel_y-30, 360, wheel_y+40], fill='#212121', outline='#000000', width=8)
    
    # Rueda trasera
    draw.ellipse([664, wheel_y-30, 734, wheel_y+40], fill='#212121', outline='#000000', width=8)
    
    # Guardar
    img.save('assets/app_icon_foreground.png')
    print('✅ Ícono foreground creado: assets/app_icon_foreground.png')

def main():
    # Crear carpeta assets si no existe
    os.makedirs('assets', exist_ok=True)
    
    print('🎨 Generando íconos para TranspoGestión CL...\n')
    
    try:
        crear_icono_principal()
        crear_icono_foreground()
        
        print('\n✅ ¡Íconos creados exitosamente!')
        print('\n📝 Próximos pasos:')
        print('1. Los íconos están en la carpeta assets/')
        print('2. Ejecuta: flutter pub run flutter_launcher_icons')
        print('3. Los íconos se aplicarán automáticamente a Android e iOS')
        
    except Exception as e:
        print(f'\n❌ Error: {e}')
        print('\n💡 Asegúrate de tener instalado Pillow:')
        print('   pip install Pillow')

if __name__ == '__main__':
    main()
