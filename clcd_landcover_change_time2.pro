PRO CLCD_landcover_change_time2

  ;T=systime(1)

  landcover_file='F:\CLCD_裁剪\合成\裁剪.dat';;inputfile

  ENVI_OPEN_FILE, landcover_file, r_fid=fid1

  ENVI_FILE_QUERY, fid1, data_type=data_type, xstart=xstart, $
    ystart=ystart, interleave=interleave, nb=nb1, nl=nl, ns=ns

  map_info=ENVI_GET_MAP_INFO(fid=fid1)
  proj_info=ENVI_GET_PROJECTION(fid=fid1)

  changetime_file='F:\CLCD_裁剪\LP_changetime.dat'  ;;output
  before_class_file='F:\CLCD_裁剪\LP_before_class.dat'  ;;output
  after_class_file='F:\CLCD_裁剪\LP_after_class.dat'  ;;output

  OPENW, unit1, changetime_file, /GET_LUN
  OPENW, unit2, before_class_file, /GET_LUN
  OPENW, unit3, after_class_file, /GET_LUN

  tile_id1 = ENVI_INIT_TILE(fid1, INDGEN(nb1), num_tiles=num_tiles, interleave=1)

  rstr=['Applying Detection']
  ENVI_REPORT_INIT, rstr, title="Processing", base=base, /interrupt
  ENVI_REPORT_INC, base, num_tiles

  FOR i=0, num_tiles-1 DO BEGIN

    ENVI_REPORT_STAT, base, i, num_tiles

    landcover = float(ENVI_GET_TILE(tile_id1, i))
    datasize=SIZE(landcover, /DIMENSIONS)
    changetime=FLTARR(datasize[0])
    before_class=FLTARR(datasize[0])
    after_class=FLTARR(datasize[0])

    FOR j=0, datasize[0]-1 DO BEGIN

      differ=FLTARR(datasize[1]-1)
      for k=1,datasize[1]-1 do begin
        differ[k-1]=landcover[j,k]-landcover[j,k-1]
      endfor

      index=where(differ eq 0,count,COMPLEMENT=index_n,NCOMPLEMENT=count_n)
      if count eq datasize[1]-1 then begin
        changetime[j]=0
        before_class[j]=landcover[j,0]
        after_class[j]=landcover[j,0]
      endif

      if count_n eq 1 then begin
        changetime[j]=index_n+1+1990.0
        before_class[j]=landcover[j,index_n]
        after_class[j]=landcover[j,index_n+1]
      endif

      if count_n gt 1 then begin
        s=0
        for p=0,count_n-1 do begin
          if index_n[p]+5 le datasize[1]-1 then temp=landcover[j,index_n[p]+1:index_n[p]+5]
          if index_n[p]+5 gt datasize[1]-1 then temp=landcover[j,index_n[p]+1:datasize[1]-1]
          indextemp=where(temp eq landcover[j,index_n[p]+1],count_temp)
          if count_temp eq 5 then begin
            changetime[j]=index_n[p]+1+1990.0
            before_class[j]=landcover[j,index_n[p]]
            after_class[j]=landcover[j,index_n[p]+1]
            s++
          endif
          if p eq count_n-1 and count_temp ge 3 then begin
            if landcover[j,index_n[p]] ge 1 and landcover[j,index_n[p]] le 4 and landcover[j,index_n[p]+1] ge 5 and landcover[j,index_n[p]+1] le 8 then begin
              changetime[j]=index_n[p]+1+1990.0
              before_class[j]=landcover[j,index_n[p]]
              after_class[j]=landcover[j,index_n[p]+1]
              s++
            endif
          endif

        endfor
        if s eq 0 then begin
          changetime[j]=0
          templandcover=landcover[j,*]
          ;his = histogram(templandcover)
          distfreq = Histogram(templandcover, MIN=Min(templandcover))
          mode = Where(distfreq EQ max(distfreq)) + Min(templandcover)
          before_class[j]=mode
          after_class[j]=mode
        endif
      endif

    ENDFOR
    IF unit1 GT 0 THEN WRITEU, unit1, changetime
    IF unit2 GT 0 THEN WRITEU, unit2, before_class
    IF unit3 GT 0 THEN WRITEU, unit3, after_class
  ENDFOR

  ENVI_REPORT_INIT, base=base, /finish
  ENVI_TILE_DONE, tile_id1
  ; ENVI_FILE_MNG, id=infid, /remove

  IF unit1 GT 0 THEN BEGIN
    CLOSE, unit1 & FREE_LUN, unit1
    ENVI_SETUP_HEAD, fname=changetime_file, ns=ns, nl=nl, nb=1, $
      data_type=4, offset=0, interleave=1,$
      xstart=xstart, ystart=ystart,$
      descrip='Savitzky-Golay Smoothed Results', /write, /open, $
      map_info=map_info
  ENDIF
  IF unit2 GT 0 THEN BEGIN
    CLOSE, unit2 & FREE_LUN, unit1
    ENVI_SETUP_HEAD, fname=before_class_file, ns=ns, nl=nl, nb=1, $
      data_type=4, offset=0, interleave=1,$
      xstart=xstart, ystart=ystart,$
      descrip='Savitzky-Golay Smoothed Results', /write, /open, $
      map_info=map_info
  ENDIF
  IF unit3 GT 0 THEN BEGIN
    CLOSE, unit3 & FREE_LUN, unit3
    ENVI_SETUP_HEAD, fname=after_class_file, ns=ns, nl=nl, nb=1, $
      data_type=4, offset=0, interleave=1,$
      xstart=xstart, ystart=ystart,$
      descrip='Savitzky-Golay Smoothed Results', /write, /open, $
      map_info=map_info
  ENDIF

  ;print,systime(1) - T,'Seconds'

END