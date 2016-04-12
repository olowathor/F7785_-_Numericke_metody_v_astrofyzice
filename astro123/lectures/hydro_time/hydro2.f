      program hydro
c     Second-order upwind scheme using van Leer's (1977) monotonic
c     derivative for a 1-D, cartesian, isothermal, ideal gas flow.
c     The grid is
c     1  1  2  2  3  3  4...i  i i+1...ig+2 ig+2 ig+3 ig+3 ig+4 ig+4
c     |  :  |  :  |  :  |   |  :  |      |    :    |    :    |    :
c        S  S  B  B  I  I   I  I  I      I    I    B    B    S    S
c     All fields run from 1:ig+4, where 1| is never used. The scalar
c     grid is shown as : (r zone centers), the vector grid as |
c     (ru zone centers; r cell interfaces). I are interior points, 
c     B boudaries, S symmetry points. Programming history:
c       7 Aug 01: van Albada, van Leer (1982) code  programmed
c       8 Aug 01: This code
c       9 Aug 01: Riemann shock tube. Solar wind
c      10 Aug 01: Riemann double shock. Solar wind. CAK wind
c      11 Aug 01: Abbott wave runaway
c
      implicit NONE
      integer i,ig,it,coo,pro,iou,ble,bri
      parameter (ig=100)
      integer iau1,iau2
      real au1,au2,vi1,vi2
      real a,a2,cfl,dt,xmi,xma,ti
      real r(ig+4),ru(ig+4),ua(ig+4),ub(ig+4),xa(ig+4),xb(ig+4),
     $     dfa(ig+4),dfb(ig+4),dva(ig+4),dvb(ig+4),g(ig+4)
      open (5,file='data.hyd2',status='unknown')
c     which problem?
      pro=5
      call setup      (ig,coo,pro,xmi,xma,ua,ub,xa,xb,
     $                 g,a,a2,cfl,it,ble,bri,vi1,vi2,iou)
      call grid       (ig,coo,pro,xmi,xma,xa,xb,dfa,dfb,
     $                 dva,dvb,vi1,vi2)
      call setup2     (ig,coo,pro,xa,g,vi1,vi2)
      call initial    (ig,pro,r,ru,xa,xb,xmi,xma,a,vi1,vi2)
      call output     (ig,r ,ru,xb,a,it,vi1,vi2)
      do i=1,it
      call speeds     (ig,r ,ru,ua,ub,vi1,vi2)
      call clock      (ig,ub,xa,a,cfl,dt,ti,vi1,vi2)
      call vanleer_r  (ig,ua,r ,xa,xb,dfa,dvb,dt,vi1,vi2)
      call vanleer_ru (ig,ub,ru,xa,xb,dfb,dva,dt,vi1,vi2)
      call pressure   (ig,r ,ru,xb,a2,dt,vi1,vi2) ! not before advection
      call gravity    (ig,r ,ru,g,dt,vi1,vi2)     ! no speed updating
      if ((pro.eq.7).or.(pro.eq.8)) then
      call radforce   (ig,r,ru,ub,xb,dt,vi1,vi2)
      call persour    (ig,r,ru,dt,ti,vi1,vi2)
      endif
      call boundary   (ig,r,ru,ble,bri,a,vi1,vi2)
      if (mod(i,iou).eq.0)
     &call output     (ig,r ,ru,xb,a,it,vi1,vi2)
      enddo
      close (5)
      stop
      end

c     -----------------------------------------------------
      subroutine vanleer_r (ig,ua,r,xa,xb,dfa,dvb,dt,vi1,vi2)
c     van leer (1977) advection for density r (b grid)
      implicit NONE
      integer i,ii,ig
      integer iau1,iau2
      real au1,au2,vi1,vi2
      real dd,dm,dp,vl,dt
      real ua(ig+4),r(ig+4),xa(ig+4),xb(ig+4),dfa(ig+4),dvb(ig+4),
     $     ri(ig+4)
c     center index of upwinded 3-molecule 
      do i=3,ig+3
      if (ua(i).gt.0.) then
         ii=i-1
      else
         ii=i
      endif
c     van Leer derivative
      dm=(r(ii)-r(ii-1))/(xb(ii)-xb(ii-1))
      dp=(r(ii+1)-r(ii))/(xb(ii+1)-xb(ii))
      dd=dm*dp
      vl=0.
      if (dd.gt.0.) vl=2.*dd/(dm+dp)
c     interface interpolants (absolute co-ord's required)
      ri(i)=r(ii)+vl*(xa(i)-xb(ii)-ua(i)*dt/2.)
      enddo
c     zone loop: advection
      do i=3,ig+2
      r(i)=r(i)-dt/dvb(i)*
     $        (ri(i+1)*ua(i+1)*dfa(i+1)-ri(i)*ua(i)*dfa(i))
      enddo
      return
      end

c     -----------------------------------------------------
      subroutine vanleer_ru (ig,ub,ru,xa,xb,dfb,dva,dt,vi1,vi2)
c     van Leer (1977) advection for momentum density ru (a grid)
      implicit NONE
      integer i,ii,ig
      integer iau1,iau2
      real au1,au2,vi1,vi2
      real dd,dm,dp,vl,dt
      real ub(ig+4),ru(ig+4),xa(ig+4),xb(ig+4),dfb(ig+4),dva(ig+4),
     $     rui(ig+4)
c     center index of upwinded 3-molecule 
      do i=3,ig+2
      if (ub(i).gt.0.) then
         ii=i
      else
         ii=i+1
      endif
c     van Leer derivative
      dm=(ru(ii)-ru(ii-1))/(xa(ii)-xa(ii-1))
      dp=(ru(ii+1)-ru(ii))/(xa(ii+1)-xa(ii))
      dd=dm*dp
      vl=0.
      if (dd.gt.0.) vl=2.*dd/(dm+dp)
c     interface interpolants
      rui(i)=ru(ii)+vl*(xb(i)-xa(ii)-ub(i)*dt/2.)
      enddo
c     zone loop: advection
      do i=4,ig+2
      ru(i)=ru(i)-dt/dva(i)*
     $        (rui(i)*ub(i)*dfb(i)-rui(i-1)*ub(i-1)*dfb(i-1))
      enddo
      return
      end

c     -----------------------------------------------------
      subroutine pressure (ig,r,ru,xb,a2,dt,vi1,vi2)
c     pressure force on ru
      implicit NONE
      integer i,ig
      integer iau1,iau2
      real au1,au2,vi1,vi2
      real dt,a2
      real r(ig+4),ru(ig+4),xb(ig+4)
      do i=4,ig+2
      ru(i)=ru(i)-a2*dt*(r(i)-r(i-1))/(xb(i)-xb(i-1))
      enddo
      return
      end

c     -----------------------------------------------------
      subroutine gravity (ig,r,ru,g,dt,vi1,vi2)
c     prescribed gravitational acceleration
      implicit NONE
      integer i,ig
      integer iau1,iau2
      real au1,au2,vi1,vi2
      real dt,a2
      real r(ig+4),ru(ig+4),g(ig+4)
      do i=4,ig+2
      ru(i)=ru(i)-dt*(r(i-1)+r(i))/2.*g(i)
      enddo
      return
      end

c     -----------------------------------------------------
      subroutine radforce (ig,r,ru,ub,xb,dt,vi1,vi2)
c     CAK (1975) line force
      implicit NONE
      integer i,ig
      integer iau1,iau2
      real au1,au2,vi1,vi2
      real r(ig+4),ru(ig+4),ub(ig+4),xb(ig+4),dt
      do i=4,ig+2
      ru(i)=ru(i)+dt*vi1*sqrt(0.5*(r(i-1)+r(i))*
     $        abs(ub(i)-ub(i-1))/(xb(i)-xb(i-1)))
      enddo
      return
      end

c     -----------------------------------------------------
      subroutine speeds (ig,r,ru,ua,ub,vi1,vi2)
c     trivial linear interpolation of advection speeds onto a,b grids
      implicit NONE
      integer i,ig
      integer iau1,iau2
      real au1,au2,vi1,vi2
      real r(ig+4),ru(ig+4),ua(ig+4),ub(ig+4)
c     For r-advection. Boundaries must be included here, (i) for
c     advection itself, (ii) to calculate ub below
      do i=3,ig+3
      ua(i)=2.*ru(i)/(r(i-1)+r(i))
      enddo
c     For ru-advection. Strangely, 5 point interpolation is better 
c     than 3-point interpolation 0.5*(ru(i)+ru(i+1))/r(i)
      do i=3,ig+2
      ub(i)=(ua(i)+ua(i+1))/2.
      enddo
      return
      end

c     -----------------------------------------------------
      subroutine clock (ig,ub,xa,a,cfl,dt,ti,vi1,vi2)
c     Courant time step
      implicit NONE
      integer i,ig
      integer iau1,iau2
      real au1,au2,vi1,vi2
      real a,cfl,dt,ti,dtt
      real ub(ig+4),xa(ig+4)
      if (cfl.lt.0.) then
         dt=-cfl
      else
         dt=1.e30
         do i=3,ig+2
         dtt=cfl*(xa(i+1)-xa(i))/(abs(ub(i))+a)
         if (dtt.lt.dt) dt=dtt
         enddo
      endif
      ti=ti+dt
      return
      end

c     -----------------------------------------------------
      subroutine setup (ig,coo,pro,xmi,xma,ua,ub,xa,xb,
     $     g,a,a2,cfl,it,ble,bri,vi1,vi2,iou)
c     fixes problem parameters and various things
      implicit NONE
      integer i,ig,it,coo,pro,iou,ble,bri
      integer iau1,iau2
      real au1,au2,vi1,vi2
      real a,a2,cfl,xmi,xma
      real ua(ig+4),ub(ig+4),xa(ig+4),xb(ig+4),g(ig+4)
      if (pro.eq.1) then ! Riemann shock tube
         a=1.
         ble=1
         bri=2
         cfl=-0.001
         coo=0
         it=200
         xmi=0.
         xma=1.
         iou=1
      else if (pro.eq.2) then ! Riemann double shock
         a=0.3
         ble=2
         bri=2
         cfl=-0.002
         coo=0
         it=int(6./5./abs(cfl))
         xmi=0.
         xma=1.
         iou=50
      else if (pro.eq.3) then ! ... shallow water Green's function?
      else if (pro.eq.4) then ! Laval nozzle
c        1-D planar flow, with area function from Liang & Chan (1989)
c        set vi1=1. for smooth flow, vi1=(any) for overloaded flow
         vi1=1.
         a=1.
         ble=1
         if (vi1.eq.1.) ble=2
         bri=2
         cfl=0.3
         coo=0
         it=int(6*ig/cfl)
         xmi=0.
         xma=1.
         iou=50
      else if (pro.eq.5) then ! solar wind
c        Normalization is a=1 and xmi=rsun=1
c        Parker equation is then (escape speed ve)
c           (v-1/v)v' = 2/r - ve^2/(2r^2)
c        Unique parameter is scale height H=2/ve^2==vi1
c        Sonic point is at r=1/(2H). For Sun, ve~3
c        Try especially: bri=1 and vmax=0.1*au1 instead of au1
c        in linear initial velocity law: breeze solution.
c        Result: shock runs in, periodic oscillations
         vi1=2./9.
         a=1.
         ble=1
         bri=1
         cfl=0.1
         coo=2
         it=50000
         xmi=1.
         xma=10.
         iou=50
      else if (pro.eq.6) then ! Velli (1994) solar wind catastrophe 
      else if (pro.eq.7) then ! stationary CAK wind
c        Model wind from accretion disk. Normalization is (ru)_cri=1
c        vi1=2*sqrt(g_c*r_c*u_c) is force proportionality constant
c        vi2 is mass loss rate in units of critical mass loss
         vi1=2.*sqrt(2./3./sqrt(3.)) ! never change
         vi2=1. ! this picks the stationary solution wanted
         a=0.
         ble=1
         bri=2
         cfl=0.2
         coo=0
         it=30000
         xmi=0.15
         xma=3.
         iou=50
      else if (pro.eq.8) then ! Abbott wave runaway
      endif ! different problems
c     Problem independent settings
      a2=a*a
      iou=it/iou
      do i=1,ig+4
         ua(i)=0.
         ub(i)=0.
      enddo
      return
      end

c     -----------------------------------------------------
      subroutine setup2 (ig,coo,pro,xa,g,vi1,vi2)
c     fixes problem parameters which depend on the grid
      implicit NONE
      integer i,ig,coo,pro
      integer iau1,iau2
      real au1,au2,vi1,vi2
      real xa(ig+4),g(ig+4)
      if (pro.le.4) then
         do i=1,ig+4
         g(i)=0.
         enddo
      else if (pro.eq.5) then
c     Solar wind. From H=a^2/g* and g~1/r^2 follows (a=1) g=1/(H*r^2)
         do i=1,ig+4
         g(i)=1./(vi1*xa(i)**2)
         enddo
      else if ((pro.eq.7).or.(pro.eq.8)) then
c     CAK wind from model accretion disks. g_max at x=1/sqrt(2).
c     v_esc=1 exact from xmi=0 to xma=inf
         do i=1,ig+4
         g(i)=xa(i)/(1.+xa(i)**2)**1.5
         enddo
      endif
      return
      end

c     -----------------------------------------------------
      subroutine initial (ig,pro,r,ru,xa,xb,xmi,xma,a,vi1,vi2)
c     fixes initial conditions for r and ru
      implicit NONE
      integer i,ig,pro
      integer iau1,iau2
      real au1,au2,vi1,vi2
      real xmi,xma,a
      real r(ig+4),ru(ig+4),xa(ig+4),xb(ig+4)
      if (pro.eq.1) then      ! Riemann shock tube
         do i=1,ig/2+2
            r(i)=1.0
            ru(i)=0.
         enddo
         do i=  ig/2+3,ig+4
            r(i)=0.1
            ru(i)=0.
         enddo
      else if (pro.eq.2) then ! Riemann double shock
         do i=1,12
            r(i)=1.
            ru(i)=1.
         enddo
         do i=13,ig+4
            r(i)=1.
            ru(i)=0.
         enddo
      else if (pro.eq.3) then ! Shallow water? 
      else if (pro.eq.4) then ! Laval nozzle
         do i=1,ig+4
         if (vi1.eq.1.) then
            r(i)=1.
            ru(i)=r(i)*(0.1+2.*xa(i)/xma)
         else
            r(i)=1.
            ru(i)=r(i)*(0.1+2.*xa(i)/xma)
         endif
         enddo
      else if (pro.eq.5) then ! solar wind
c        grid index of sonic point
         iau1=int(ig/(2.*vi1)/xma)
         do i=1,iau1
c        spherical barometric up to sonic point
         r(i)=exp((1./xb(i)-1./xmi)/vi1) ! vi1=H scale height
         enddo
         au1=r(iau1)*xb(iau1)**2
         do i=iau1+1,ig+4
c        decline ~1/r^2 above sonic point
         r(i)=au1/xb(i)**2
         enddo
c        linear velocity law, H=2/ve^2 with ve=v_esc
         au1=sqrt(2./vi1)
         do i=1,ig+4
         ru(i)=r(i)*(0.1+0.1*au1*(xa(i)-xmi)/(xma-xmi))
         enddo
      else if ((pro.eq.7).or.(pro.eq.8)) then ! CAK wind
         do i=1,ig+4
         ru(i)=vi2
         enddo
         do i=3,ig+4
         r(i)=vi2/(0.05+3.*(xb(i)-xmi)/(xma-xmi))
         enddo
         r(2)=r(3)
      endif
      return
      end

c     -----------------------------------------------------
      subroutine boundary (ig,r,ru,ble,bri,a,vi1,vi2)
c     boundary values for r and ru. 
c     Simple upwind boundary conditions: ble=1/bri=1 for subsonic
c     inflow/outflow; ble=2/bri=2 for supersonic inflow/outflow
      implicit NONE
      integer i,ig,ble,bri
      integer iau1,iau2
      real au1,au2,vi1,vi2
      real a,r(ig+4),ru(ig+4)
c     left boundary conditions
      if (ble.eq.1) then      ! subsonic inflow: fix 1, extrapolate 1
         r(2) =r(2)
         ru(3)=ru(4)
      else if (ble.eq.2) then ! supersonic inflow: fix 2
         r(2) =r(2)
         ru(3)=ru(3)
      endif
c     right boundary conditions
      if (1.eq.2) then ! automatic characteristic switch
      if (ru(ig+3)/r(ig+2).gt.a) then
         bri=2
      else
         bri=1
      endif
      endif ! 1.eq.2
      if (bri.eq.1) then      ! subsonic outflow: fix 1, extrapolate 1
         r(ig+3) =r(ig+2)
         ru(ig+3)=ru(ig+3)
      else if (bri.eq.2) then ! supersonic outflow: extrapolate 2
         r(ig+3) =r(ig+2)
         ru(ig+3)=ru(ig+2)
      endif
c     symmetry reductions
      r(1)=r(2)
      ru(2)=ru(3)
      r(ig+4)=r(ig+3)
      ru(ig+4)=ru(ig+3)
      return
      end

c     -----------------------------------------------------
      subroutine grid
     $     (ig,coo,pro,xmi,xma,xa,xb,dfa,dfb,dva,dvb,vi1,vi2)
c     the grid: scalars (like r) are defined on zone center (b) grid,
c     vectors (like ru) on (a) interface grid
      implicit NONE
      integer i,ig,coo,pro
      integer iau1,iau2
      real au1,au2,vi1,vi2
      real xmi,xma
      real xa(ig+4),xb(ig+4),dfa(ig+4),dfb(ig+4),dva(ig+4),dvb(ig+4)
      do i=1,ig+4
      xa(i)=xmi+(xma-xmi)*(i-3.)/float(ig)
      enddo
      do i=1,ig+3
      xb(i)=(xa(i)+xa(i+1))/2.
      enddo
      xb(ig+4)=2.*xb(ig+3)-xb(ig+2)
c     control volumes and interface areas. Cartesian coordinates
      if (coo.eq.0) then
         do i=1,ig+4
         dfa(i)=1.
         dfb(i)=1.
         enddo
         if (pro.eq.4) then ! Laval nozzle area function
            do i=1,ig+4
            if (xa(i).le.0.5) then
               dfa(i)=1.+2.*(0.5-xa(i))**2
               dfb(i)=1.+2.*(0.5-xb(i))**2
            else
               dfa(i)=1.+6.*(0.5-xa(i))**2
               dfb(i)=1.+6.*(0.5-xb(i))**2
            endif
            enddo
         endif ! Laval
         do i=2,ig+4
         dva(i)=(xb(i)-xb(i-1))*dfa(i)
         enddo
         dva(1)=dva(2)
         do i=1,ig+3
         dvb(i)=(xa(i+1)-xa(i))*dfb(i)
         enddo
         dvb(ig+4)=dvb(ig+3)
      else if (coo.eq.2) then
c     Or: spherical coordinates. A factor of 4*pi is left out, as it would
c     cancel
         do i=1,ig+4
         dfa(i)=xa(i)**2
         dfb(i)=xb(i)**2
         enddo
         do i=2,ig+4
         dva(i)=(xb(i)**3-xb(i-1)**3)/3.
         enddo
         dva(1)=dva(2)
         do i=1,ig+3
         dvb(i)=(xa(i+1)**3-xa(i)**3)/3.
         enddo
         dvb(ig+4)=dvb(ig+3)
      endif ! cartesian vs spherical
      return
      end

c     -----------------------------------------------------
      subroutine output (ig,r,ru,xb,a,it,vi1,vi2)
c     writes output to file
      implicit NONE
      integer i,ig,it
      integer iau1,iau2
      real au1,au2,vi1,vi2
      real dtodx,a
      real r(ig+4),ru(ig+4),xb(ig+4)
      do i=3,ig+2
      write (5,*) xb(i),r(i),ru(i)
      enddo
      return
      end

c     -----------------------------------------------------
      subroutine persour (ig,r,ru,dt,ti,vi1,vi2)
c     creates Abbott wave perturbations in line driven winds
      implicit NONE
      integer i,ig
      integer iau1,iau2
      real au1,au2,vi1,vi2
      real r(ig+4),ru(ig+4),dt,ti,pi
      pi=3.1415927
      iau1=15  ! location
      au1=0.1  ! amplitude
      au2=0.2   ! period
      ru(iau1)=ru(iau1)+r(iau1)*dt*au1*2.*pi/au2*cos(2.*pi*ti/au2)
      return
      end

