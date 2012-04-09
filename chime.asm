chime:
    sidwsi  0x18, 0x0F  ; volume
    
    sidwsi  0x01, 0x0E  ; frequency   
    sidwsi  0x00, 0x6B  ; frequency  
    sidwsi  0x05, 0x8A  ; attack / decay
    sidwsi  0x06, 0x08  ; sustain / release
    sidwsi  0x04, 0x21  ; waveform / gate

    sidwsi  0x08, 0x12  ; frequency   
    sidwsi  0x07, 0x2A  ; frequency  
    sidwsi  0x0C, 0x8A  ; attack / decay 
    sidwsi  0x0D, 0x08  ; sustain / release       
    sidwsi  0x0B, 0x21  ; waveform / gate
    
    sidwsi  0x0F, 0x15  ; frequency   
    sidwsi  0x0E, 0x9A  ; frequency         
    sidwsi  0x13, 0x8A  ; attack / decay 
    sidwsi  0x14, 0x08  ; sustain / release       
    sidwsi  0x12, 0x21  ; waveform / gate

    ret
