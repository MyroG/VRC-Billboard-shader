# VRC 3D Billboard Shader
This is a very basic unlit billboard shader, optimized for VRChat. It basically flattens any mesh based on the position of the camera, so from far away the mesh looks three dimensional, but it's actually 2D!

<img src="https://i.imgur.com/4knFNx0.png" height=100/>
<img src="https://i.imgur.com/RgkCQwF.png" height=100/>
<img src="https://i.imgur.com/Duh4ds3.png" height=100/>
<img src="https://i.imgur.com/FP6M1wq.png" height=100/>

## Settings

This shader has three settings :
#### 1) Main texture
#### 2) Thickness on the flat side (float)
To get the billboard effect, keep this value low, but I wouldn't recommend using 0 as it can cause z-fighting issues.
0 means "totally flat" and 1 means "default thickness".
#### 3) Thickness on the larger side (float)
This setting exists mostly for fun and allows you to stretch the mesh, keep this value at 1 if you want a billboard effect.
0 means "totally flat" (the mesh won't be really visible) and 2 means "two times as large"
Here's a little example with "Thickness on the larger side" set to 0.3
<img src="https://i.imgur.com/xZPIadp.png" height=100/>
