PRO detect_changetime

  IFZ_data='G:\1990-2022_landcover3.dat'

  ENVI_OPEN_FILE, IFZ_data, r_fid=fid1

  ENVI_FILE_QUERY, fid1, data_type=data_type, xstart=xstart, $
    ystart=ystart, interleave=interleave, nb=nb1, nl=nl, ns=ns

  map_info=ENVI_GET_MAP_INFO(fid=fid1)
  proj_info=ENVI_GET_PROJECTION(fid=fid1)

  SG_result='G:\crop2fsg_changtime.dat'

  OPENW, unit1, SG_result, /GET_LUN

  tile_id1 = ENVI_INIT_TILE(fid1, INDGEN(nb1), num_tiles=num_tiles, interleave=1)
  ; tile_id2 = ENVI_INIT_TILE(fid2, INDGEN(nb2), num_tiles=num_tiles, interleave=1)

  rstr=['Applying Detection']
  ENVI_REPORT_INIT, rstr, title="Processing", base=base, /interrupt
  ENVI_REPORT_INC, base, num_tiles

  FOR i=0L, num_tiles-1 DO BEGIN

    ENVI_REPORT_STAT, base, i, num_tiles
    data=ENVI_GET_TILE(tile_id1, i)
    ;mask=ENVI_GET_TILE(tile_id2, i)

    datasize=SIZE(data,/DIMENSIONS)

    sg_data=intarr(datasize[0])
    ;result=FLTARR(datasize[0])

    FOR j=0, datasize[0]-1 DO BEGIN

      index=where(~finite(data[j,*]),count)

      if count eq datasize[1] or mean(data[j,*]) eq 0 then continue

      temp=data[j,*]

      index1=where(temp eq 1,count1)  ;;landcover type

      ;index2=where(temp ge 2 and temp le 4,count2)

      if count1 eq 0 or count1 eq datasize[1] then continue
      
      ;if count2 eq 0 or count2 eq datasize[1] then continue

     ; if count1+count2 ne datasize[1] then contiue
      
      
      if index1[0] ne 0 then continue  ;;loss
      if index1[0] eq 0 then sg_data[j]=1990+index1[count1-1]+1 ;;loss

      ;if index1[count1-1] ne datasize[1]-1 then continue ;;gain
      ;if index1[count1-1] eq datasize[1]-1 then sg_data[j]=1990+index1[0]  ;;gain
      
      
      
      
      

    ENDFOR

    IF unit1 GT 0 THEN WRITEU, unit1, sg_data

  ENDFOR

  ENVI_REPORT_INIT, base=base, /finish
  ENVI_TILE_DONE, tile_id1
  ;ENVI_TILE_DONE, tile_id2
  ; ENVI_FILE_MNG, id=infid, /remove

  IF unit1 GT 0 THEN BEGIN
    CLOSE, unit1 & FREE_LUN, unit1
    ENVI_SETUP_HEAD, fname=SG_result, ns=ns, nl=nl, nb=1, $
      data_type=2, offset=0, interleave=1, $
      xstart=xstart, ystart=ystart,fwhm=fwhm,wl=wl, $
      descrip='Savitzky-Golay Smoothed Results', /write, /open, $
      map_info=map_info
  ENDIF

  ;print,systime(1) - T,'Seconds'

END