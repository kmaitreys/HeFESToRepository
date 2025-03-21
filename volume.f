        function volume(ispec,x1)
        include 'P1'

C  Find the volume of species ispec, given pressure Pi, and temperature Ti
	double precision x1,apar,fret,Pi,pressure,Ti,vlan,vlow,Vo,vsplow,vspupp,vupp,vsp
	double precision x2,xx,volume,zeroin,pxb1,pxb2,pv,Ko,Kop,Vmur,vl,vu
	double precision p1,p2,plow,pupp,vmurnaghan
	integer ispec,ires,jspec,nb,nseg
        logical isochor
        double precision xb1(10),xb2(10)
        common /state/ apar(nspecp,nparp),Ti,Pi
        common /chor/ jspec,isochor
        external pressure
        double precision, parameter :: tol=1.e-15, vsmall=1.0, vreldiff=0.3

C  Set bounds on the volume
	jspec = ispec
	vlan = apar(ispec,40)
	vlow = apar(ispec,51)
	vupp = apar(ispec,52)
	vsplow = apar(ispec,53)
	vspupp = apar(ispec,54)
	vl = max(vlow,vsplow)
	vu = min(vupp,vspupp)
c	vlow = vl
c	vupp = vu
c	print*, 'Vibrational limits on volume',vlow,vupp
c	print*, 'K limits on volume',vsplow,vspupp

	Ko = apar(ispec,7)
	Kop = apar(ispec,8)
        Vo = apar(ispec,6)
	Vmur = Vo*(1. + Pi*(Kop/Ko))**(-1./Kop)
c	x1 = vmurnaghan(ispec)
C  Fix volume to Vo and return if isochoric conditions have been chosen
        if (isochor) then
         volume = Vo
         Pi = pressure(Vo)
         return
        end if
C  Find volume by cage using the last succesfully found volume as guess (x1)
        x2 = x1*(1.0 + tol)
c	write(31,*) 'Calling cage the first time',vlow,vupp
c	print*, 'In volume entering cage and pressure',vlow,vupp,x1,Pi,Ti
	call cage(pressure,x1,x2,vlow,vupp,ires)
        p1 = pressure(x1)
        p2 = pressure(x2)
        plow = pressure(vlow)
        pupp = pressure(vupp)
	if (ires .eq. 1) then
         volume = zeroin(x1,x2,pressure,tol)
c	 write(31,*) 'Found volume by zbrac',ispec,volume,Pi,Ti,x1,x2,vlow,vupp
c	 print*, 'Found volume by zbrac',ispec,volume,Pi,Ti,x1,x2,p1,p2,vlow,vupp,plow,pupp,ires
	 return
	end if
C  cage failed.  The following logic assumes that if a solution Vsol exists,
C  it satisfies Vo < Vsol < vupp, and that Vsol=Vsp, where Vsp is the spinodal volume on the T=Ti isotherm.
C  Find the spinodal volume by minimizing the pressure.
c        write(31,*) 'volume Failed to find V cage',ispec,Pi,Ti,x1,x2
c	print *, 'volume Failed to find V cage',ispec,Ti,Pi,x1,x2,p1,p2,vlow,vupp,plow,pupp,ires
        x1 = Vo - vlan
        x2 = vupp
	xx = x2*(1. - tol)
	call nlmin_V(xx,x1,x2,fret,ires)
	vsp = xx
c        write(31,*) 'volume spinodal',ispec,Pi,Ti,x1,x2,vsp,fret,ires
c        print*, 'volume spinodal',ispec,Pi,Ti,x1,x2,vsp,fret,ires
C  Value of function pressure is positive at Vsp: no solution.
        if (fret .gt. 0. .and. ires .gt. 0) then
	 x1 = Vo
         volume = -1
         return
        end if
	if (ires .lt. 0) then
	 x1 = Vo
	 volume = -2
	 return
	end if
C  Find volume by zbrak.  Search between V=Vo and V=Vsp
	x1 = Vo
	x2 = vsp
        nb = 10
	nseg = 10
	call cages(pressure,x1,x2,nseg,xb1,xb2,nb)
        if (nb .ge. 1) then
         volume = zeroin(xb1(1),xb2(1),pressure,tol)
	 pxb1 = pressure(xb1(1))
	 pxb2 = pressure(xb2(1))
	 pv = pressure(volume)
c         write(31,*) 'volume by zbrak',ispec,Pi,Ti,x1,x2,xb1(1),xb2(1),pxb1,pxb2,volume,pv
c         print*, 'volume by zbrak',ispec,Pi,Ti,x1,x2,xb1(1),xb2(1),pxb1,pxb2,volume,pv
	 return
	end if
	if (nb .lt. 1) then
C  Zbrak failed.
c         write(31,*) 'WARNING: Volume failed to find V zbrak',ispec,Pi,Ti,x1,x2,xb1(1),xb2(1),pxb1,pxb2,volume,pv
         volume = -2
        end if

C  For testing only: use the Murnaghan eos for the initial guess at the volume
c	if (abs(log(volume/Vmur)) .gt. vreldiff .and. vlan .eq. 0.) then
c	 x1 = Vmur
c         x2 = x1*(1.0 + tol)
cc         write(31,*) 'Calling cage with V Murnaghan',ispec,volume,Vmur,vlan,apar(ispec,40),apar(jspec,40)
c         print*, 'Calling cage with V Murnaghan',ispec,volume,Vmur,vlan,apar(ispec,40),apar(jspec,40)
c         call cage(pressure,x1,x2,vlow,vupp,ires)
c         if (ires .eq. 1) then
c          volume = zeroin(x1,x2,pressure,tol)
c          write(31,*) 'Found volume by zbrac',ispec,volume,Pi,Ti,x1,x2,vlow,vupp
c	 end if
c	end if

        return
        end
