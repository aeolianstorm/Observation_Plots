;======================================================================
; animate_3_1.ncl
;
; Concepts illustrated:
;   - Creating animations
;   - Animating WRF reflectivity data over a terrain map across time
;   - Using get_cpu_time to calculate the CPU time for a script to execute
;   - Drawing partially transparent filled contours
;   - Drawing raster and smooth contours
;   - Using two different colormaps on one frame
;======================================================================
; This example generates an animation aross time of filled contours of
; reflectivity overlaid on a terrain map. The reflectivity field changes
; with each time step, while the terrain map is static.
;
; This example shows the more "traditional" way of generating both sets
; of contours, by calling "gsn_csm_contour", "gsn_csm_contour_map" and
; "overlay" inside a "do" loop. This method can be slow if you have a 
; lot of time steps, or if you are needlessly regenerating the same plot 
; over and over (like the terrain map). 
;
; See animate_3_2.ncl and animate_3_3.ncl for faster methods of
; generating these plots.
;
;http://forum.wrfforum.com/viewtopic.php?f=32&t=3639
;======================================================================
;***********************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
;***********************************************
; TAU must match size of times or less PL!

begin
  start_cpu_time = get_cpu_time()     ; We will time this example

;---Open files
  dir   = "/home/amos/Desktop/No_CU_2012_0920_ANC/"
  files = systemfunc("ls " + dir + "wrfout_d01_2012-09*")
  a     = addfiles(files,"r")



; Find the ij location for the point if interest
;######## Double check these!!  One typo messes this up PL!
lat = 61.21
lon = -149.90
llres = True
llres@ReturnInt = True ; Return integer values
locij = wrf_user_ll_to_ij(a, lon, lat, llres)
print(locij)
locij = locij - 1 ; array pointers in NCL space
print(locij)
locX = locij(0)
print(locX)
locY = locij(1)
print(locY)

 ; printVarSummary(locij)
 ; printVarSummary(locX)
 ; printVarSummary(locY)

;---Read variables
  hgt   = a[:]->HGT(0,:,:)                 ; terrain, 0 is the first time step
  dbz   = wrf_user_getvar(a,"dbz",-1)      ; reflectivity
  times = wrf_user_list_times(a)
   taus = ispan(1,17,1) ; integer
  printMinMax(dbz,0)
  printVarSummary(dbz)

t2 = wrf_user_getvar(a,"T2",-1) ; get t2 for all times
t2=t2-273.15
t2@description="Temp.(C)"
slp = wrf_user_getvar(a,"slp",-1) ; get slp for all times
tc = wrf_user_getvar(a,"tc",-1) ; get tc for all times
uvmet = wrf_user_getvar(a,"uvmet",-1) ; get rotated u and v comp of wind
tc = wrf_user_getvar(a,"tc",-1) ; get tc for all times
rain_exp = wrf_user_getvar(a,"RAINNC",-1)
rain_con = wrf_user_getvar(a,"RAINC",-1)
rain = rain_exp + rain_con

 wks = gsn_open_wks("ps","meteo_2012_PL") ; open a workstation

;----------------------------------------------------



gsn_define_colormap(wks,"WhBlGrYeRe")
rain_res = True
t2 = wrf_user_getvar(a,"T2",-1) ; get t2 for all times
t2=t2-273.15
t2@description="Temp.(C)"
slp = wrf_user_getvar(a,"slp",-1) ; get slp for all times
tc = wrf_user_getvar(a,"tc",-1) ; get tc for all times
uvmet = wrf_user_getvar(a,"uvmet",-1) ; get rotated u and v comp of wind
tc = wrf_user_getvar(a,"tc",-1) ; get tc for all times
rain_exp = wrf_user_getvar(a,"RAINNC",-1)
rain_con = wrf_user_getvar(a,"RAINC",-1)
rain = rain_exp + rain_con

temp = dimsizes(rain)
print (temp)
nt = temp(0)
print (nt)
new_rain = rain(1:nt-1,:,:) - rain(0:nt-2,:,:)

printVarSummary(t2)
printVarSummary(slp)
printVarSummary(tc)
printVarSummary(uvmet)
printVarSummary(rain)
umet = uvmet(0,:,:,:,:)
vmet = uvmet(1,:,:,:,:)

;-----------------------------------------------------------------------
rain_point = new_rain(:,locY,locX)
t2_point = t2(:,locY,locX) ; extract a time series at a point
slp_point = slp(:,locY,locX)
tc_point = tc(:,:,locY,locX)

u_point = umet(:,:,locY,locX)
v_point = vmet(:,:,locY,locX)

; Swap the dimensions as we want to plot time on the X axis later
tt = tc_point(bottom_top|:,Time|:)
ugrid = u_point(bottom_top|:,Time|:)
vgrid = v_point(bottom_top|:,Time|:)

;-----------------------------------------------------------------------



;-----------------------------------------------------------------------

res1D = True ; Set basic resources both will use
res1D@vpXF = 0.15 ; The left side of the box location
res1D@vpWidthF = 0.70 ; The Width of the plot box
res1D@vpHeightF = 0.10 ; The height of the plot box
res1D@tmXBMode = "Explicit" ; Define own tick mark labels.
res1D@tmXBValues = taus ; location of explicit labels
res1D@tmXBLabels = times ; labels are the locations
res1D@tmXTOn = False ; turn off the top tick marks
res1D@xyLineThicknesses = 2 ; increase line thickness
res1D@gsnDraw = False ; Don't draw individual plot.
res1D@gsnFrame = False ; Don't advance frame.
; res1D@gsnAddCyclic = False
res1D@tmLabelAutoStride = True

slp_res = res1D
slp_res@vpYF = 0.50 ; The top side of the plot box loc
slp_res@xyLineColor = "red" ; set line color
slp_res@tiYAxisString = "P (nm)" ; set y-axis string


t2_res = res1D
t2_res@vpYF = 0.35 ; The top side of the plot box loc
t2_res@xyLineColor = "blue" ; set line color

;-----------------------------------------------------------------------



;-----------------------------------------------------------------------

res2D = True ; Set basic resources
res2D@gsnDraw = False ; Don't draw individual plot.
res2D@gsnFrame = False ; Don't advance frame.
res2D@vpXF = 0.15 ; x location
res2D@vpYF = 0.90 ; y location
res2D@vpWidthF = 0.65 ; width
res2D@vpHeightF = 0.30 ; height
res2D@tiXAxisString = "Date"
res2D@tiXAxisFontHeightF = 0.016
res2D@tmXBMode = "Explicit"
res2D@tmXBValues = taus
res2D@tmXBLabels = times
res2D@trYMaxF = 16
res2D@tmXBLabelJust = "CenterCenter"
res2D@tmXBLabelFontHeightF = .012
; res2D@gsnAddCyclic = False
res2D@tmLabelAutoStride = True
tt_res = res2D
tt_res@sfXArray = taus
;tt_res@gsnAddCyclic = False
tt_res@gsnSpreadColors = True ; use full range of colors
tt_res@cnFillOn = True ; turns on color fill
tt_res@cnLevelSelectionMode = "ManualLevels" ; set levels manually
tt_res@cnMinLevelValF = -60.
tt_res@cnMaxLevelValF = 40.
tt_res@cnLevelSpacingF = 5
tt_res@cnLinesOn = False
tt_res@cnLineLabelsOn = False
tt_res@cnInfoLabelOn = False
tt_res@pmLabelBarDisplayMode = "Always" ; Add a label bar
tt_res@pmLabelBarSide = "right"
; tt_res@lbOrientation = "vertical"
tt_res@pmLabelBarOrthogonalPosF = -0.05
tt_res@pmLabelBarParallelPosF = 0.04
tt_res@lbAutoManage = False
tt_res@lbLabelAutoStride = True
tt_res@lbOrientation = "vertical"
tt_res@lbPerimOn = False
tt_res@lbJustification = "BottomLeft"
tt_res@lbBoxMinorExtentF = 0.13
tt_res@lbLabelFontHeightF = 0.012
tt_res@lbBoxLinesOn = False
tt_res@tiMainString = "Anchorage,AK Sept 2012 noCU 3km"
; tt_res@gsnAddCyclic = False

uv_res = res2D
uv_res@vfXArray = taus
;uv_res@gsnAddCyclic = False
uv_res@vcRefAnnoOn = False ; turns off the ref vector
uv_res@vcRefLengthF = 0.040 ; set length of ref vector
uv_res@vcGlyphStyle = "WindBarb" ; turn on wind barbs


;-----------------------------------------------------------------------

res1D = True ; Set basic resources both will use
res1D@vpXF = 0.15 ; The left side of the box location
res1D@vpWidthF = 0.70 ; The Width of the plot box
res1D@vpHeightF = 0.10 ; The height of the plot box
res1D@tmXBMode = "Explicit" ; Define own tick mark labels.
res1D@tmXBValues = taus ; location of explicit labels
res1D@tmXBLabels = times ; labels are the locations
res1D@tmXTOn = False ; turn off the top tick marks
res1D@xyLineThicknesses = 2 ; increase line thickness
res1D@gsnDraw = False ; Don't draw individual plot.
res1D@gsnFrame = False ; Don't advance frame.
; res1D@gsnAddCyclic = False
res1D@tmLabelAutoStride = True

slp_res = res1D
slp_res@vpYF = 0.50 ; The top side of the plot box loc
slp_res@xyLineColor = "red" ; set line color
slp_res@tiYAxisString = "P (nm)" ; set y-axis string


t2_res = res1D
t2_res@vpYF = 0.35 ; The top side of the plot box loc
t2_res@xyLineColor = "blue" ; set line color

;-----------------------------------------------------------------------







;***********************************************
; rain histogram only resources
;***********************************************
rain_res = res1D
rain_res@vpXF = 0.15 ; The left side of the box location
rain_res@vpYF = 0.20 ; The top side of the plot box location
rain_res@vpWidthF = 0.70 ; The Width of the plot box
rain_res@vpHeightF = 0.10 ; The height of the plot box

rain_res@tiXAxisString = "" ; X axis label.
rain_res@tiYAxisString = "Prec. (mm)" ; Y axis label.
rain_res@tmXBMode = "Explicit" ; Define own tick mark labels.
rain_res@tmXBValues = taus ; location of explicit labels
rain_res@tmXBLabels = times
rain_res@tmXTOn = False ; turn off the top tickmarks
rain_res@trYMinF = 0.0 ; min value on y-axis
rain_res@trYMaxF = 30.0 ; min value on y-axis
rain_res@trXMinF = 0.0 ; min value on x-axis
rain_res@xyLineThicknesses = 2
rain_res@tmXBMinorOn = False ; No minor tick marks.
rain_res@gsnDraw = False ; Don't draw individual plot.
rain_res@gsnFrame = False ; Don't advance frame.
rain_res@gsnYRefLine = 0.0 ; create a reference line
rain_res@gsnAboveYRefLineColor = "green" ; above ref line fill green
rain_res@gsnXYBarChart = True ; turn on bar chart


printVarSummary(rain)


;-----------------------------------------------------------------------

ttfill = gsn_contour(wks,tt,tt_res)
windlayer = gsn_vector(wks,ugrid,vgrid,uv_res)
overlay(ttfill,windlayer)

slp_plot = gsn_csm_xy(wks,taus,slp_point,slp_res)
t2_plot = gsn_csm_xy(wks,taus,t2_point,t2_res)
rain_plot = gsn_csm_xy(wks,taus,rain_point,rain_res)

draw(ttfill)
draw(slp_plot)
draw(t2_plot)
draw(rain_plot)
frame(wks) ; now frame the plot

;-----------------------------------------------------------------------

end


