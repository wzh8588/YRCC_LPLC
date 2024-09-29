pro changetime_class_filter

  ;for k=1980,2013 do begin
  ;data_if=DIALOG_PICKFILE(/READ, FILTER = '*.dat',title='please input inputfile name', /MULTIPLE_FILES)
  ;data_if='M:\DB_NPP\DB_meteo\test_P_T\temp\'+STRCOMPRESS(k,/remove_all)+'_temp.dat'
  inputfile='F:\1990-2022_class1.dat'
  ;FOR k=0L,N_ELEMENTS(data_if)-1 DO BEGIN

  ENVI_OPEN_FILE, inputfile, r_fid=infid

  ENVI_FILE_QUERY, infid, data_type=data_type, xstart=xstart, $
    ystart=ystart, interleave=interleave, nb=nb, nl=nl, ns=ns,$
    fname=fname1,bnames=bnames1

  map_info=ENVI_GET_MAP_INFO(fid=infid)
  proj_info=ENVI_GET_PROJECTION(fid=infid)

  ;outname=FILE_DIRNAME(data_if)+'\'+strmid(file_basename(data_if),10,10)+'_NDVI.dat'      ;+'GPP_ANN_'+STRCOMPRESS(1980+k,/remove_all)+'_yearly.dat'
  outname='F:\1990-2022_class_filter2.dat'


  OPENW, unit1, outname, /GET_LUN


  tile_id1 = ENVI_INIT_TILE(infid, INDGEN(nb), num_tiles=num_tiles, interleave=1)

  rstr=['Applying Stddev']
  ENVI_REPORT_INIT, rstr, title="Processing", base=base, /interrupt
  ENVI_REPORT_INC, base, num_tiles

  FOR i=0L, num_tiles-1 DO BEGIN

    ENVI_REPORT_STAT, base, i, num_tiles
    class = ENVI_GET_TILE(tile_id1, i)

    datasize=SIZE(class, /DIMENSIONS)
    stddev_NDVI=fltarr(datasize[0],nb)
    ;year2=strarr(nb)
    FOR j=0, datasize[0]-1 DO BEGIN

      ;      a=finite(summer_max[j,*],/nan)
      ;      index=where(a eq 1,countnan)
      ;      if countnan ge 1 then continue
      if mean(class[j,*]) eq 0 then continue       

      ;count1=0
      ;stddev_NDVI[j,0:1]=class[j,0:1]
      ;stddev_NDVI[j,nb-2:nb-1]=class[j,nb-2:nb-1]

      for k=2,nb-3 do begin
        temp=[class[j,k-2:k+2]]
        
        index1=where(temp eq 1,count1)
        index2=where(temp eq 2,count2)
        
        if count1 ge 3 then stddev_NDVI[j,k]=1
        if count2 ge 3 then stddev_NDVI[j,k]=2
        
        class[j,k]=stddev_NDVI[j,k]      

      endfor
      
      
      stddev_NDVI[j,0:1]=stddev_NDVI[j,2]
      stddev_NDVI[j,nb-2:nb-1]=stddev_NDVI[j,nb-3]
 
    endfor

    IF unit1 GT 0 THEN WRITEU, unit1, stddev_NDVI
    ;iimage,stddev_ndvi[1,1329]

  ENDFOR

  ENVI_REPORT_INIT, base=base, /finish
  ENVI_TILE_DONE, tile_id1
  ;ENVI_FILE_MNG, id=infid, /remove

  IF unit1 GT 0 THEN BEGIN
    CLOSE, unit1 & FREE_LUN, unit1
    ENVI_SETUP_HEAD, fname=outname, ns=ns, nl=nl, nb=nb, $
      data_type=4, offset=0, interleave=1, $
      xstart=xstart, ystart=ystart, $
      descrip='NDVI_Stddev Calculated Results', /write, /open, $
      map_info=map_info,bnames=bnames1
  ENDIF

  ; endfor

END



