### A Pluto.jl notebook ###
# v0.14.1

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 7504b100-929b-11eb-36c4-09285f1ac3d6
begin
	using Plots
	#plotly()
end

# ╔═╡ de0851a0-929d-11eb-0f51-7d9c41f3440a
md"# Simulation of steel truss design

### Henki W. Ashadi, Universitas Indonesia

#### henki.ashadi@gmail.com,henki@eng.ui.ac.id"

# ╔═╡ f5188c58-8f0c-45ef-a7a9-794a187516e8
md"""
![image](https://user-images.githubusercontent.com/6933510/114436067-35e51400-9bc5-11eb-9ee3-909ffb7b5fd7.png)
"""

# ╔═╡ 22138b16-5f15-4bac-adfb-35f9a1d8928d
md" In order to design a structure, we need to analyse the structure and evaluating the internal forces at each structural members and its deflection produce by design loads.

Several technical decision should be made to fullfill the good practice of design are :
- Selecting the efficient, economical structural form
- Evaluating the strength, stiffness, and deflections to achieve a serviceable structure
- Simulate many loading case, different systems, and steel section will develop a sense of how the structural behave, to prevent the eccessive deflection and impaired its function.

We use the stiffness method to solve the equation of equilibrium.  We write the equilibrium equation in term of unknown joint displacement and stiffness coefficient (forces produced by unit displacement). Once the joint displacement is known, the internal forces of the structure can be calculated using the force-displacement relationship.
"

# ╔═╡ 6937c70a-d570-4abc-9623-ef36e1fe24ea
md"- Equilibrium equations of the system : `` k_{ff} \cdot \Delta = R_f``"

# ╔═╡ 39771e0e-f2fb-4942-b6ac-1da589437e26
md"- Constructing the element global stiffness matrix

The element stiffness matrix in global coordinate system can be define as  

``K_{global}= \begin{bmatrix}\cos \theta & 0\\ \sin \theta & 0\\0 & \cos \theta \\ 0 & \sin \theta \end{bmatrix}\frac{E A}{l} \begin{bmatrix} 1 & -1 \\ -1 & 1\end{bmatrix}\begin{bmatrix} \cos \theta & \sin \theta & 0 &0 \\  & 0& 0&\cos \theta &  \sin \theta\end{bmatrix}``"

# ╔═╡ 3e95d5be-61eb-48ae-ba61-db464de184cf
md"Example of stiffness matrix element 7 :"

# ╔═╡ a8861134-0ae4-4e3f-8792-3bf3b7bc6033
md"The stiffness matrix of the structure system is :"#

# ╔═╡ 5d72d668-3535-4c71-9b4f-d3d88ea692f1
md" - After swapping the zeros displacement DOF we get the following stiffness matrix"

# ╔═╡ 6811a6ba-5abc-4431-b07d-a6b66cee2804
md"- We define the nodal load `` R_f`` according to the govern building code"

# ╔═╡ 1892ef56-0b72-4801-b1e3-5da5ad1bc38d
md"Solving the equilibrium equation using `` d= k_{ff} \backslash R_f``, we get the displacement for each degree of freedom as follow :"

# ╔═╡ d117ab1b-808b-4abd-97a7-b232e0d3d6a9
md"- Internal Force can be define using the following formula

`` N=\frac{E A}{l} \begin{bmatrix}-\cos \theta & -\sin \theta & \cos \theta & \sin \theta \end{bmatrix} \begin{Bmatrix} u_1 \\ v_1 \\u_2\\v_2\end{Bmatrix}``"

# ╔═╡ 0ebd8729-7b37-4fef-bf91-f9da042d6add
md"Node coordinate of the truss : "

# ╔═╡ edc5e7b6-446a-49e0-8700-bb87ff79e0ee
md"
- Setup maximum deflection of the structure ``\Delta/240``

- Using A36 steel : f_y = 240 N/mm2"

# ╔═╡ 108b180e-3766-4073-bde2-53824b4e9936
md"The simulation will be done using roof angle, length of the structure, area of the steel section members. Also the load at the bottom cords, top cords may applied to the truss systems."

# ╔═╡ 3eb3d820-92bd-11eb-3ed3-81e3a5e34c34
begin
	tl=@bind l html"<input type=range min=5 max=30 default=10>"
	ta=@bind ang html"<input type=range min=5 max=45 default=20>"
	ts=@bind a html"<input type=range min=700e-6 max=20000e-6 step=0.001>"
	md"Angle : $ta Length : $tl ; Section area : $ts"
end

# ╔═╡ 9df96c00-929a-11eb-21cd-9bacb278d733
begin
b=6;an=ang*pi/180
function fh(x,an,l)
    if x ≤ l/2
        h=x*tan(an)
    else
        h=(tan(an)*l/2)-((x-l/2)*tan(an))
    end
end

yb=zeros(b+1,1)
lx=[i*l/b  for i=0:b]

yu=fh.(lx,an,l)

xb=collect(1:b+1)
xu=[i for i in (b+2:2b)]

nb=[1:b+1 lx yb]
nu=[ b+2:2b lx[2:b] yu[2:b]]
nid=vcat(nb,nu)
end

# ╔═╡ c1772714-be59-4311-b918-6ae8db53db49
Δmax= l/240

# ╔═╡ d4dd1554-9480-11eb-18eb-fdc22ebd0952
begin
	tpa=@bind pa html"<input type=range min=-50 max=0 default=0>"
	tpb=@bind pb html"<input type=range min=-50 max=0 default=0>"
	tph=@bind ph html"<input type=range min=-20 max=20 default=0>"
	md"Pby : $tpb kN; Pty : $tpa  kN ; Pth : $tph kN"
end

# ╔═╡ 84eb8ab2-9480-11eb-0e86-e1c0ac633363
begin
	#   4   5  6   7   8    9  10  11  12 13  3 15 16 17 18 19 20 21  22 23 24  
   Rf=[pb, 0., pb, 0., pb, 0., pb, 0., pb, 0, 0,ph,pa,ph,pa,ph,pa,ph, pa,ph,pa]
end

# ╔═╡ a551fd3d-ffec-43e8-aa86-f7bce99b6999
md"Angle = $(ang) ``^\circ``, Length = $l m, Area = $a m2, Pa= $pa kN, Pb= $pb kN, Ph= $ph kN "

# ╔═╡ 4cdb7b01-0ab0-4858-ad34-6e533aaaaef0
md"Node ``\quad``  Displ-x, m ``\quad \,``  Displ-y, m ``\quad`` Internal Force, kN ``\quad`` Stress F/a, N/mm2"

# ╔═╡ b9727178-e8f1-4bb9-bbf3-e4bc78e720d7
begin
#fungsi untuk menghitung panjang, sudut cos, dan sudut sin
function fe(xi, yi, xj, yj)
    l = sqrt((xj-xi)^2+(yj-yi)^2)
    c = (xj-xi)/l
    s = (yj-yi)/l
    return l,c,s
end


function fk(ks,ke,ni,nj)
    ks[2ni-1:2ni,2ni-1:2ni]+=ke[1:2,1:2]
    ks[2nj-1:2nj,2ni-1:2ni]+=ke[3:4,1:2]
    ks[2ni-1:2ni,2nj-1:2nj]+=ke[1:2,3:4]
    ks[2nj-1:2nj,2nj-1:2nj]+=ke[3:4,3:4]
    return ks
end

function swaprow(ksa,i,j)
    ksa[i,:], ksa[j,:] = ksa[j,:], ksa[i,:]
end

function swapcolumn(ksa,i,j)
    ksa[:,i], ksa[:,j] = ksa[:,j], ksa[:,i]
end

function swaprowcol(ksa,i,j)
    ksa[i,:], ksa[j,:] = ksa[j,:], ksa[i,:]
    ksa[:,i], ksa[:,j] = ksa[:,j], ksa[:,i]
end

function fkg(ea,l,c,s)
    k = (ea/l).*[c^2 c*s -c^2 -c*s; c*s s^2 -c*s -s^2 ;
        -c^2 -c*s c^2 c*s ; -c*s -s^2 c*s s^2]
    return k
end

function fkg2(ea,e)
    l,c,s=e
    k = (ea/l).*[c^2 c*s -c^2 -c*s; c*s s^2 -c*s -s^2 ;
        -c^2 -c*s c^2 c*s ; -c*s -s^2 c*s s^2]
    return k
end

function fN1(ea,e1,u1,v1,u2,v2)
    l,c,s=e1
    N=(ea/l)*[-c -s c s]*[u1; v1;u2;v2]
 return N
end


function fN11(ea,e1,u1,v1,u2,v2)
    l,c,s=e1
    N=(ea/l).*[1 -1;-1 1]*[c s 0 0; 0 0 c s]*[u1; v1;u2;v2]
 return N
end

end

# ╔═╡ 41a20fae-92c3-11eb-1217-81e1a71e2a6b
begin
e=200e6
#a=700e-6
ea=e*a
	# nid, x, y
#nid=[1 0 0 ; 2 5 0 ; 3 10 0 ; 4 15 0 ; 5 20 0 ; 6 25 0 ; 7 30 0 ;
#     8 5 2.88 ; 9 10 5.77 ; 10 15 8.66 ; 11 20 5.77 ; 12 25 2.88 ]

# eid, i, j
#eid = [1 1 2 ;2 2 3 ;3 3 4 ;4 4 5 ;5 5 6 ; 6 6 7;
#      7 1 8 ;8 8 9 ;9 9 10 ;10 10 11 ;11 11 12 ;
#     12 7 12 ;13 2 8 ;14 3 8 ;15 3 9 ;16 4 9 ;
#     17 4 10 ;18 4 11 ;19 5 11 ;20 5 12 ;21 6 12 ]

# A plot
# using Plots
# eld=[0 0 ; 5 0 ;10 0 ;15 0;20 0;25 0;30 0;25 2.88;20 5.77;15 8.66;10 5.77;5 2.88;0 0 ; NaN NaN ; 5 0 ; 5 2.88; 10 0; 10 5.77; 15 0; 20 5.77;20 0;25 2.88;25 0 ; NaN NaN ; 15 0 ; 15 8.66]
# scatter(nid[:,2],nid[:,3], legend=false,size=(800,200))
# plot!(eld[:,1],eld[:,2])

# Another Plots
# plot(size=(600,200),nid[1:7,2],nid[1:7,3],color=:blue,legend=false)
# plot!(nid[[1 8 9 10 11 12 7],2]',nid[[1 8 9 10 11 12 7],3]',color=:blue)
# plot!(nid[[2 8 3 9 4 10 4 11 5 12 6],2]',nid[[2 8 3 9 4 10 4 11 5 12 6], 3]',color=:blue)

#fungsi 



# elemen 1 : node 1 to node 2
e1=fe(nid[1,2],nid[1,3],nid[2,2],nid[2,3])
# matrix elemen local
kg1 =fkg2(ea,e1)
# elemen 2 : node 2 to node 3
e2=fe(nid[2,2],nid[2,3],nid[3,2],nid[3,3])
kg2 =fkg2(ea,e2)
# elemen 3 : node 3 to node 4
e3=fe(nid[3,2],nid[3,3],nid[4,2],nid[4,3])
kg3 =fkg2(ea,e3)
# elemen 4 : node 4 to node 5
e4=fe(nid[4,2],nid[4,3],nid[5,2],nid[5,3])
kg4 =fkg2(ea,e4)
# elemen 5 : node 5 to node 6
e5=fe(nid[5,2],nid[5,3],nid[6,2],nid[6,3])
kg5 =fkg2(ea,e5)
# elemen 6 : node 6 to node 7
e6=fe(nid[6,2],nid[6,3],nid[7,2],nid[7,3])
kg6 =fkg2(ea,e6)

# elemen 7 : node 1 to node 8
e7=fe(nid[1,2],nid[1,3],nid[8,2],nid[8,3])
kg7 =fkg2(ea,e7)
# elemen 8 : node 8 to node 9
e8=fe(nid[8,2],nid[8,3],nid[9,2],nid[9,3])
kg8 =fkg2(ea,e8)
# elemen 9 : node 9 to node 10
e9=fe(nid[9,2],nid[9,3],nid[10,2],nid[10,3])
kg9 =fkg2(ea,e9)
# elemen 10 : node 10 to node 11
e10=fe(nid[10,2],nid[10,3],nid[11,2],nid[11,3])
kg10 =fkg2(ea,e10)
# elemen 11 : node 11 to node 12
e11= fe(nid[11,2],nid[11,3],nid[12,2],nid[12,3])
kg11 =fkg2(ea,e11)
# elemen 12 : node 7 to node 12
e12= fe(nid[7,2],nid[7,3],nid[12,2],nid[12,3])
kg12 =fkg2(ea,e12)
# Batang pengisi

# elemen 13 : node 2 to node 8
e13= fe(nid[2,2],nid[2,3],nid[8,2],nid[8,3])
kg13 =fkg2(ea,e13)
# elemen 14 : node 3 to node 8
e14= fe(nid[3,2],nid[3,3],nid[8,2],nid[8,3])
kg14 =fkg2(ea,e14)
# elemen 15 : node 3 to node 9
e15= fe(nid[3,2],nid[3,3],nid[9,2],nid[9,3])
kg15 =fkg2(ea,e15)
# elemen 16 : node 4 to node 9
e16= fe(nid[4,2],nid[4,3],nid[9,2],nid[9,3])
kg16 =fkg2(ea,e16)
# elemen 17 : node 4 to node 10
e17= fe(nid[4,2],nid[4,3],nid[10,2],nid[10,3])
kg17 =fkg2(ea,e17)
# elemen 18 : node 4 to node 11
e18= fe(nid[4,2],nid[4,3],nid[11,2],nid[11,3])
kg18 =fkg2(ea,e18)
# elemen 19 : node 5 to node 11
e19= fe(nid[5,2],nid[5,3],nid[11,2],nid[11,3])
kg19 =fkg2(ea,e19)
# elemen 20 : node 5 to node 12
e20=fe(nid[5,2],nid[5,3],nid[12,2],nid[12,3])
kg20 =fkg2(ea,e20)
# elemen 21 : node 6 to node 12
e21= fe(nid[6,2],nid[6,3],nid[12,2],nid[12,3])
kg21 =fkg2(ea,e21)

elid=[e1;e2;e3;e4;e5;e6;e7;e8;e9;e10;e11;e12;e13;e14;e15;e16;e17;e18;e19;e20;e21]

# matrix elemen global : u1,v1,u2,v2,u3,v3,u4,v4,u5,v5,u6,v6,u7,v7,u8,v8,u9,v9,u10,v10,u11,v11,u12,v12
ks = zeros(24,24)

fk(ks,kg1,1,2);fk(ks,kg2,2,3);fk(ks,kg3,3,4)
fk(ks,kg4,4,5);fk(ks,kg5,5,6);fk(ks,kg6,6,7)
fk(ks,kg7,1,8);fk(ks,kg8,8,9);fk(ks,kg9,9,10)
fk(ks,kg10,10,11);fk(ks,kg11,11,12);fk(ks,kg12,7,12)
fk(ks,kg13,2,8);fk(ks,kg14,3,8);fk(ks,kg15,3,9);
fk(ks,kg16,4,9);fk(ks,kg17,4,10);fk(ks,kg18,4,11);
fk(ks,kg19,5,11);fk(ks,kg20,5,12);fk(ks,kg21,6,12)

ksa=copy(ks)

swaprowcol(ksa,3,14)

kff=ksa[4:24,4:24]

#displacement
d=kff\Rf

u=[0;0;d[:11];d[:1];d[:2];d[:3];d[:4];d[:5];d[:6];d[:7];d[:8];d[:9];
 d[:10];0;d[:12];d[:13];d[:14];d[:15];d[:16];d[:17];d[:18];d[:19];d[:20];d[:21]]

# uxy=reshape(u,2,12)'

N1= fN1(ea,e1, u[:1] ,u[:2] ,u[:3] ,u[:4])
N2= fN1(ea,e2, u[:3] ,u[:4] ,u[:5] ,u[:6])
N3= fN1(ea,e3, u[:5] ,u[:6] ,u[:7] ,u[:8])
N4= fN1(ea,e4, u[:7] ,u[:8] ,u[:9] ,u[:10])
N5= fN1(ea,e5, u[:9] ,u[:10],u[:11],u[:12])
N6= fN1(ea,e6, u[:11],u[:12],u[:13],u[:14])
N7= fN1(ea,e7, u[:1] ,u[:2] ,u[:15],u[:16])
N8= fN1(ea,e8, u[:15],u[:16],u[:17],u[:18])
N9= fN1(ea,e9, u[:17],u[:18],u[:19],u[:20])
N10=fN1(ea,e10,u[:19],u[:20],u[:21],u[:22])
N11=fN1(ea,e11,u[:21],u[:22],u[:23],u[:24])
N12=fN1(ea,e12,u[:23],u[:24],u[:13],u[:14])
N13=fN1(ea,e13,u[ :3],u[:4] ,u[:15],u[:16])
N14=fN1(ea,e14,u[:15],u[:16],u[:5] ,u[:6])
N15=fN1(ea,e15,u[:5] ,u[:6] ,u[:17],u[:18])
N16=fN1(ea,e16,u[:17],u[:18],u[:7] ,u[:8])
N17=fN1(ea,e17,u[:7] ,u[:8] ,u[:19],u[:20])
N18=fN1(ea,e18,u[:7] ,u[:8] ,u[:21],u[:22])
N19=fN1(ea,e19,u[:9] ,u[:10],u[:21],u[:22])
N20=fN1(ea,e20,u[:9] ,u[:10],u[:23],u[:24])
N21=fN1(ea,e21,u[:11],u[:12],u[:23],u[:24])

#GAYA DALAM
N=[N1; N2; N3; N4; N5; N6; N7; N8; N9; N10; N11; N12; N13; N14; N15;N16;N17; N18; N19; N20; N21];
R=[N;0;0;0]
rxy= reshape(R,2,12)'
uxy= reshape(u,2,12)'
str= rxy ./(a .* 1000)
[1:12 uxy rxy str]
end

# ╔═╡ 52003910-9299-11eb-2794-4990921cda0d
kg4

# ╔═╡ f3f5efb8-ded4-40b6-8c2c-7d6a22acca50
ksa

# ╔═╡ 7ccd443a-4cd9-420e-af31-fe5e0b170a15
kff

# ╔═╡ 81f570e2-3e93-4c88-8ad9-7c2e437ac0ee
u

# ╔═╡ 58294d20-929b-11eb-0f7e-797beee1ff43
# Another Plots
begin
	fac=1
    xn=nid[1:12,2].+fac.*uxy[1:12,1];
    yn=nid[1:12,3].+fac.*uxy[1:12,2];
    plot(size=(750,300),nid[1:7,2],nid[1:7,3],color=:purple,lw=2,legend=false,ylims=(-.5,5.1),xlims=(0,25))
    plot!(nid[[1 8 9 10 11 12 7],2]',nid[[1 8 9 10 11 12 7],3]',lw=2,color=:purple)
    plot!(nid[[2 8 3 9 4 10 4 11 5 12 6],2]',nid[[2 8 3 9 4 10 4 11 5 12 6],
			3]',color=:purple,lw=2)
	plot!(xn[1:7],yn[1:7],color=:green,lw=2)
    plot!(xn[[1 8 9 10 11 12 7]]',yn[[1 8 9 10 11 12 7]]',color=:green,lw=2)
    plot!(xn[[2 8 3 9 4 10 4 11 5 12 6]]',yn[[2 8 3 9 4 10 4 11 5 12 6]]',color=:green,lw=2)
	hline!([-Δmax],color=:blue,linestyle=:dash)
end

# ╔═╡ Cell order:
# ╟─de0851a0-929d-11eb-0f51-7d9c41f3440a
# ╟─f5188c58-8f0c-45ef-a7a9-794a187516e8
# ╟─22138b16-5f15-4bac-adfb-35f9a1d8928d
# ╟─6937c70a-d570-4abc-9623-ef36e1fe24ea
# ╟─39771e0e-f2fb-4942-b6ac-1da589437e26
# ╟─3e95d5be-61eb-48ae-ba61-db464de184cf
# ╠═52003910-9299-11eb-2794-4990921cda0d
# ╟─a8861134-0ae4-4e3f-8792-3bf3b7bc6033
# ╠═f3f5efb8-ded4-40b6-8c2c-7d6a22acca50
# ╟─5d72d668-3535-4c71-9b4f-d3d88ea692f1
# ╠═7ccd443a-4cd9-420e-af31-fe5e0b170a15
# ╟─6811a6ba-5abc-4431-b07d-a6b66cee2804
# ╟─84eb8ab2-9480-11eb-0e86-e1c0ac633363
# ╟─1892ef56-0b72-4801-b1e3-5da5ad1bc38d
# ╠═81f570e2-3e93-4c88-8ad9-7c2e437ac0ee
# ╟─d117ab1b-808b-4abd-97a7-b232e0d3d6a9
# ╟─0ebd8729-7b37-4fef-bf91-f9da042d6add
# ╟─9df96c00-929a-11eb-21cd-9bacb278d733
# ╟─7504b100-929b-11eb-36c4-09285f1ac3d6
# ╟─edc5e7b6-446a-49e0-8700-bb87ff79e0ee
# ╠═c1772714-be59-4311-b918-6ae8db53db49
# ╟─108b180e-3766-4073-bde2-53824b4e9936
# ╟─58294d20-929b-11eb-0f7e-797beee1ff43
# ╟─a551fd3d-ffec-43e8-aa86-f7bce99b6999
# ╟─3eb3d820-92bd-11eb-3ed3-81e3a5e34c34
# ╟─d4dd1554-9480-11eb-18eb-fdc22ebd0952
# ╟─4cdb7b01-0ab0-4858-ad34-6e533aaaaef0
# ╟─41a20fae-92c3-11eb-1217-81e1a71e2a6b
# ╟─b9727178-e8f1-4bb9-bbf3-e4bc78e720d7
