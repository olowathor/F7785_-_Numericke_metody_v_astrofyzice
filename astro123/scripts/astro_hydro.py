import numpy as np
import scipy


class Hydro():

    def __init__(self,resolution,geometry,sound_speed,courant,min_x,max_x):

        self.resolution = resolution
        self.geometry = geometry

        self.a = sound_speed

        self.cfl = courant
        
        self.rho = np.empty(self.resolution+4)*np.nan
        self.rho_u = np.empty(self.resolution+4)*np.nan

        self.ua = np.empty(self.resolution+4)*np.nan
        self.ub = np.empty(self.resolution+4)*np.nan

        self.xa = np.empty(self.resolution+4)*np.nan
        self.xb = np.empty(self.resolution+4)*np.nan

        self.dfa = np.empty(resolution+4)*np.nan
        self.dfb = np.empty(self.resolution+4)*np.nan

        self.dva = np.empty(self.resolution+4)*np.nan
        self.dvb = np.empty(self.resolution+4)*np.nan
        
        self.g = np.empty(self.resolution+4)*np.nan

        self.a2 = self.a*self.a
        self.dt = np.nan
        self.ti = 0.0
        self.it = 50000
        
        self.min_x = min_x
        self.max_x = max_x

        self.vi1 = np.nan
        self.vi2 = np.nan
        
        self.ble = 1 
        self.bri = 1


    def van_leer_rho(self):
    
        ri = np.empty(self.resolution+4)*np.nan

        for i in range(2,self.resolution+3):

            if self.ua[i] > 0:
                ii = i -1
            else:
                ii = i

            
            dm = (self.rho[ii]-self.rho[ii-1])/(self.xb[ii]-self.xb[ii-1])
            dp = (self.rho[ii+1]-self.rho[ii])/(self.xb[ii+1]-self.xb[ii])

            dd = dm*dp
            v1 = 0.0

            if dd > 0:

                v1 = 2.*dd/(dm+dp)

            ri[i] = self.rho[ii]+v1*(self.xa[i]-self.xb[ii]-self.ua[i]*self.dt/2.)

            
        for i in range(2,self.resolution+2):
            self.rho[i] = self.rho[i]-self.dt/self.dvb[i]*(ri[i+1]*self.ua[i+1]*self.dfa[i+1]-ri[i]*self.ua[i]*self.dfa[i])

    def van_leer_rho_u(self):
        
        rho_u_i = np.empty(self.resolution+4)*np.nan

        for i in range(2,self.resolution+2):

            if self.ub[i] > 0:
                ii = i

            else:
                ii = i + 1

            
            dm = (self.rho_u[ii]-self.rho_u[ii-1])/(self.xa[ii]-self.xa[ii-1])
            dp = (self.rho_u[ii+1]-self.rho_u[ii])/(self.xa[ii+1]-self.xa[ii])

            dd = dm*dp
            v1 = 0

            if dd > 0 :
                    v1 = 2.*dd/(dm+dp)

            rho_u_i[i] = self.rho_u[ii]+v1*(self.xb[i]-self.xa[ii]-self.ub[i]*self.dt/2.)


        for i in range(3,self.resolution+2):
            
            self.rho_u[i] = self.rho_u[i]-self.dt/self.dva[i]*(rho_u_i[i]*self.ub[i]*self.dfb[i]-rho_u_i[i-1]*self.ub[i-1]*self.dfb[i-1])

        return

    def grid(self):

        step = np.float(self.max_x - self.min_x)/self.resolution

        self.xa = np.linspace(self.min_x-2.*step,self.max_x+2*step,self.resolution+4)
        
        for i in range(0,self.resolution+3):

            self.xb[i] = (self.xa[i]+self.xa[i+1])/2.

        self.xb[self.resolution+3] = 2.0*self.xb[self.resolution+2]-self.xb[self.resolution+2]
    
        # Control volumes - spherical coordinates

        for i in range(self.resolution+4):
            self.dfa[i] = self.xa[i]**2
            self.dfb[i] = self.xb[i]**2

        for i in range(1,self.resolution+4):
            self.dva[i] = (self.xb[i]**3-self.xb[i-1]**3)/3.

        for i in range(self.resolution+3):
            self.dvb[i] = (self.xa[i+1]**3-self.xa[i]**3)/3.

        self.dva[0] = self.dva[1]
        self.dvb[self.resolution+3] = self.dvb[self.resolution+2]

    def speeds(self):

        for i in range(2,self.resolution+3):
            self.ua[i] = 2.*self.rho_u[i]/(self.rho[i-1]+self.rho[i])

        for i in range(2,self.resolution+2):
            self.ub[i] = (self.ua[i]+self.ua[i+1])/2.

        return

    def clock(self):

        if self.cfl < 0.:

            self.dt = -self.cfl
        
        else:
            self.dt = 1.e30
            for i in range(2,self.resolution+2):
                dtt = self.cfl*(self.xa[i+1]-self.xa[i])/(np.abs(self.ub[i])+self.a)
                
                if (dtt < self.dt):
                    self.dt = dtt
                    
        self.ti = self.ti + self.dt
        return            

    def pressure(self):

        for i in range(3,self.resolution+2):
            self.rho_u[i]=self.rho_u[i]-self.a2*self.dt*(self.rho[i]-self.rho[i-1])/(self.xb[i]-self.xb[i-1])

	return

    def gravity(self):

        for i in range(3,self.resolution+2):
            self.rho_u[i] = self.rho_u[i]-self.dt*(self.rho[i-1]+self.rho[i])/(2.*self.g[i])

	return


    def setup(self):

    # Solar wind example

        self.vi1 = 2./9.
        self.vi2 = 1.
        self.g = 1./(self.vi1*self.xa**2)


    def initial(self):

        i1 = np.int(self.resolution/(2.*self.vi1)/(self.max_x))

        for i in range(0,i1):
            self.rho[i] = np.exp(1./self.xb[i]-1./self.min_x)
            
        au1 = self.rho[i1-1]*self.xb[i1-1]**2

        for i in range(i1,self.resolution+4):
            self.rho[i] = au1/self.xb[i]**2

        au1 = np.sqrt(2.0/self.vi1)

        self.rho_u = self.rho*(0.1+0.1*au1*(self.xa-self.min_x)/(self.max_x-self.min_x))

	return

    def boundary(self):

        if self.ble == 1:
            self.rho[1] = self.rho[1]
            self.rho_u[2] = self.rho_u[3]

        elif self.ble == 1:
            self.rho[1] = self.rho[1]
            self.rho_u[2] = self.rho_u[2]


        if self.bri == 1:
            self.rho[self.resolution+2] = self.rho[self.resolution+1]
            self.rho_u[self.resolution+2] = self.rho[self.resolution+2]

        elif self.bri == 2:
            self.rho[self.resolution+2] = self.rho[self.resolution+1]
            self.rho_u[self.resolution+2] = self.rho_u[self.resolution+1]

        # Symmetry reduction

        self.rho[0] = self.rho[1]
        self.rho_u[1] = self.rho_u[2]
        self.rho[self.resolution+3] = self.rho[self.resolution+2]
        self.rho_u[self.resolution+3] = self.rho_u[self.resolution+2]

    def run(self):

        steps = 0
        
        self.grid()
        self.setup()
        self.initial()

        while (steps < self.it):

            self.speeds()
            self.clock()
            self.van_leer_rho()
            self.van_leer_rho_u()
            self.pressure()
            self.gravity()
            self.boundary()
            
            steps +=1

        return self.rho,self.rho_u

