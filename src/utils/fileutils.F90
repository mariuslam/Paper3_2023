module fileutils

  !-----------------------------------------------------------------------
  ! !DESCRIPTION:
  ! Module containing file I/O utilities
  !
  ! !USES:
  use shr_sys_mod , only : shr_sys_abort
  use clm_varctl  , only : iulog
  use spmdMod     , only : masterproc
  !
  ! !PUBLIC TYPES:
  implicit none
  save
  !
  ! !PUBLIC MEMBER FUNCTIONS:
  public :: get_filename  !Returns filename given full pathname
  public :: opnfil        !Open local unformatted or formatted file
  public :: getfil        !Obtain local copy of file
  public :: relavu        !Close and release Fortran unit no longer in use
  public :: getavu        !Get next available Fortran unit number
  !-----------------------------------------------------------------------

contains

  !-----------------------------------------------------------------------
  character(len=256) function get_filename (fulpath)
    !
    ! !DESCRIPTION:
    ! Returns filename given full pathname
    !
    ! !ARGUMENTS:
    character(len=*), intent(in)  :: fulpath !full pathname
    !
    ! !LOCAL VARIABLES:
    integer i               !loop index
    integer klen            !length of fulpath character string
    !------------------------------------------------------------------------

    klen = len_trim(fulpath)
    do i = klen, 1, -1
       if (fulpath(i:i) == '/') go to 10
    end do
    i = 0
10  get_filename = fulpath(i+1:klen)

    return
  end function get_filename

  !------------------------------------------------------------------------
  subroutine getfil (fulpath, locfn, iflag)
    !
    ! !DESCRIPTION:
    ! Obtain local copy of file
    ! First check current working directory
    ! Next check full pathname[fulpath] on disk
    ! 
    ! !USES:
    use shr_file_mod, only: shr_file_get
    !
    ! !ARGUMENTS:
    character(len=*), intent(in)  :: fulpath !Archival or permanent disk full pathname
    character(len=*), intent(out) :: locfn   !output local file name
    integer,          intent(in)  :: iflag   !0=>abort if file not found 1=>do not abort
    !
    ! !LOCAL VARIABLES:
    integer i               !loop index
    integer klen            !length of fulpath character string
    logical lexist          !true if local file exists
    !------------------------------------------------------------------------

    ! get local file name from full name
    locfn = get_filename( fulpath )
    if (len_trim(locfn) == 0) then
       if (masterproc) then
          write(iulog,'(a)')'(GETFIL): full pathname is '//trim(fulpath)
          write(iulog,'(a)')'(GETFIL): local filename has zero length'
       end if
       call shr_sys_abort
    else
       if (masterproc) then
          write(iulog,'(a)')'(GETFIL): attempting to find local file ',trim(locfn)
       end if
    endif

    ! first check if file is in current working directory.
    inquire (file=locfn,exist=lexist)
    if (lexist) then
       if (masterproc) then
          write(iulog,'(a)') '(GETFIL): using '//trim(locfn)//' in current working directory'
       end if
       RETURN
    endif

    ! second check for full pathname on disk
    locfn = fulpath
    inquire (file=fulpath,exist=lexist)
    if (lexist) then
       if (masterproc) then
          write(iulog,'(a)') '(GETFIL): using '//trim(fulpath)
       end if
       RETURN
    else
       if (masterproc) then
          write(iulog,'(a)')'(GETFIL): failed getting file from full path: '//fulpath
       end if
       if (iflag==0) then
          call shr_sys_abort ('GETFIL: FAILED to get '//trim(fulpath))
       else
          RETURN
       endif
    endif

  end subroutine getfil

  !------------------------------------------------------------------------
  subroutine opnfil (locfn, iun, form)
    !
    ! !DESCRIPTION:
    ! Open file locfn in unformatted or formatted form on unit iun
    !
    ! !ARGUMENTS:
    character(len=*), intent(in):: locfn  !file name
    integer, intent(in):: iun             !fortran unit number
    character(len=1), intent(in):: form   !file format: u = unformatted, f = formatted
    !
    ! !LOCAL VARIABLES:
    integer ioe             !error return from fortran open
    character(len=11) ft    !format type: formatted. unformatted
    !------------------------------------------------------------------------

    if (len_trim(locfn) == 0) then
       write(iulog,*)'(OPNFIL): local filename has zero length'
       call shr_sys_abort
    endif
    if (form=='u' .or. form=='U') then
       ft = 'unformatted'
    else
       ft = 'formatted  '
    end if
    open (unit=iun,file=locfn,status='unknown',form=ft,iostat=ioe)
    if (ioe /= 0) then
       write(iulog,*)'(OPNFIL): failed to open file ',trim(locfn),        &
            &     ' on unit ',iun,' ierr=',ioe
       call shr_sys_abort
    else if ( masterproc )then
       write(iulog,*)'(OPNFIL): Successfully opened file ',trim(locfn),   &
            &     ' on unit= ',iun
    end if

  end subroutine opnfil

  !------------------------------------------------------------------------
  integer function getavu()
    !
    ! !DESCRIPTION:
    ! Get next available Fortran unit number.
    !
    ! !USES:
    use shr_file_mod, only : shr_file_getUnit
    !------------------------------------------------------------------------

    getavu = shr_file_getunit()

  end function getavu

  !------------------------------------------------------------------------
  subroutine relavu (iunit)
    !
    ! !DESCRIPTION:
    ! Close and release Fortran unit no longer in use!
    !
    ! !USES:
    use shr_file_mod, only : shr_file_freeUnit
    !
    ! !ARGUMENTS:
    integer, intent(in) :: iunit    !Fortran unit number
    !------------------------------------------------------------------------

    close(iunit)
    call shr_file_freeUnit(iunit)

  end subroutine relavu

end module fileutils
