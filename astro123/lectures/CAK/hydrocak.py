import numpy as np
from scipy import linalg
from scipy.constants import sigma
from astropysics.constants import c,h,mp,me,Rs,Ms,Lsun,kb,g0,G

class HydroCAK:
    
    def __init__(self,resolution,rho_boundary,rmin,rmax):
        
        self.resolution = resolution
        
        self.r = np.empty(resolution)*np.nan
        self.rho = np.empty(resolution)*np.nan
        self.velocity = np.empty(resolution)*np.nan
        self.gravity = np.empty(resolution)*np.nan
        self.dvdr = np.empty(resolution)*np.nan
        self.drhodr = np.empty(resolution)*np.nan
        self.cak_crit_condition = np.empty(self.resolution)*np.nan

        self.p_operator_phi = np.empty(resolution*2)*np.nan
        self.phi = np.empty(resolution*2)*np.nan
        self.jakobian = np.empty((resolution*2,resolution*2))*np.nan
        self.delta_phi = np.zeros(resolution*2)
    
        self.rmin = rmin
        self.rmax = rmax
        self.a = np.nan
        self.rho_boundary = rho_boundary
        
        self.x_cak = 1.
        self.alpha = 0.5 
        self.beta = 0.5
        self.a = 0.1
        self.velocity_infty = 0.5
        self.Gamma = 0.
        self.gm = 1.
        self.mass_conserve = np.nan
    
    def grid(self):
        mesh = np.linspace(self.rmin,self.rmax,self.resolution)
        self.r = self.rmax*np.exp(np.log(mesh/self.rmax))
        
    def initial(self):
        self.velocity[0] = self.a
        self.rho[0] = self.rho_boundary
        
        for i in range(self.resolution):
            self.gravity[i] = self.gm/self.r[i]**2
            
        for i in range(1,self.resolution):
            self.velocity[i] = self.velocity_infty*(1.-1./self.r[i])
            self.rho[i] = self.mass_conserve/(self.r[i]**2*self.velocity[i])
        
    def derivative(self):
        # Inner boundary derivative (never used)
        self.dvdr[0] = 0
        self.drhodr[0] = 0
        
        # Centered on space derivative
        for i in range(1,self.resolution-1):
            self.dr = (self.r[i+1]-self.r[i-1])/2.
            
            self.dvdr[i] = (self.velocity[i+1]-self.velocity[i-1])/(2.*self.dr)
            
            self.drhodr[i] = (self.rho[i+1]-self.rho[i-1])/(2.*self.dr)
        
        # Outer boundary derivative
        self.dr = (self.r[self.resolution-1]-self.r[self.resolution-2])

        self.dvdr[self.resolution-1] = (self.velocity[self.resolution-1]- \
        self.velocity[self.resolution-2])/(2.*self.dr)
        
        self.drhodr[self.resolution-1] = (self.rho[self.resolution-1]- \
        self.rho[self.resolution-2])/(2.*self.dr)
            
    def p_calculate(self):

        # Continuity differential variable
        continuity = np.empty(self.resolution)
        continuity = self.r**2*self.rho*self.velocity
        
        # Inner boundary condition
        self.p_operator_phi[0] = self.rho[0] - self.rho_boundary
        self.p_operator_phi[1] = self.velocity[0] - self.a
                
        for i in range(1,self.resolution-1):
            self.dr = (self.r[i+1]-self.r[i-1])/2.

            self.p_operator_phi[2*i] = (continuity[i+1]- \
            continuity[i-1])/(self.r[i]**2*2.*self.dr)
            
            self.p_operator_phi[2*i+1] =  self.velocity[i]*self.dvdr[i]+ \
            self.gravity[i]+self.a**2*self.drhodr[i]/self.rho[i]+ \
            -self.x_cak/self.r[i]**2*(self.dvdr[i]/self.rho[i])**self.alpha
            
        # Outer boundary condition
        i = self.resolution-1
        self.dr = self.r[i]-self.r[i-1]
        
        self.p_operator_phi[2*i] = (continuity[i]- \
        continuity[i-1])/(self.r[i]**2*self.dr)
        
        self.p_operator_phi[2*i+1] = self.velocity[i]*self.dvdr[i]+ \
        self.a**2/self.rho[i]*self.drhodr[i]-self.gravity[i]-self.x_cak* \
        (1./self.rho[i]*self.dvdr[i])**self.alpha
        
        return self.p_operator_phi
        
    def jakobian_calculate(self):
        self.jakobian = np.zeros((self.resolution*2,self.resolution*2))
        
        self.jakobian[0,0] = 1.
        self.jakobian[1,1] = 1.
        
        for i in range(1,self.resolution-1):
            
            # Space step for centered in space mesh
            self.dr = (self.r[i+1]-self.r[i-1])
            
            # Jacobian part for continuum equation
            self.jakobian[2*i,2*i-2] = -(self.r[i-1]**2*self.velocity[i-1])/ \
            (self.r[i]**2*2*self.dr)
            
            self.jakobian[2*i,2*i-1] = -(self.r[i-1]**2*self.rho[i-1])/ \
            (self.r[i]**2*2*self.dr)
            
            self.jakobian[2*i,2*i] = 0
            
            self.jakobian[2*i,2*i+1] = 0
            
            self.jakobian[2*i,2*i+2] = (self.r[i+1]**2*self.velocity[i+1])/ \
            (self.r[i]**2*2*self.dr)
            
            self.jakobian[2*i,2*i+3] = (self.r[i+1]**2*self.rho[i+1])/ \
            (self.r[i]**2*2*self.dr)
            
            # Jacobian part for momentum equation
            self.jakobian[2*i+1,2*i-2] = -self.a**2/(self.rho[i]   \
            *2*self.dr)
            
            self.jakobian[2*i+1,2*i-1] = -self.velocity[i]/(2.*self.dr) + \
            self.x_cak*self.alpha*(1.0/self.rho[i]*(self.velocity[i+1] - \
            self.velocity[i-1])/(2.0*self.dr))**(self.alpha-1.0)*\
            1.0/(self.rho[i]*2.0*self.dr)

            self.jakobian[2*i+1,2*i] = -self.a**2/(self.rho[i]**2)* \
            (self.rho[i+1]-self.rho[i-1])/(2*self.dr)+self.x_cak*self.alpha* \
            1./self.rho[i]**(self.alpha+1)* \
            (self.velocity[i+1]-self.velocity[i-1])/(2.*self.dr)**(self.alpha)
            
            self.jakobian[2*i+1,2*i+1] = (self.velocity[i+1]-self.velocity[i-1]) \
            /(2.*self.dr)
            
            self.jakobian[2*i+1,2*i+2] = self.a**2/(self.rho[i]*2.*self.dr)
            
            self.jakobian[2*i+1,2*i+3] = self.velocity[i]/(2.*self.dr)- \
            self.x_cak*self.alpha*(1./self.rho[i]*(self.velocity[i+1]- \
            self.velocity[i-1])/(2.*self.dr))*1./(self.rho[i]*2.*self.dr)
            
         # Outward boundary condition

        i = self.resolution-1
        self.dr = (self.r[i]-self.r[i-1])
        
        # Jacobian for continuity equation on outer boundary
        self.jakobian[2*i,2*i-2] = -1./self.r[i]**2*(self.r[i-1]**2* \
        self.velocity[i-1])/self.dr
        
        self.jakobian[2*i,2*i-1] = -1./self.r[i]**2*(self.r[i-1]**2* \
        self.rho[i-1]/self.dr)
        
        self.jakobian[2*i,2*i] = self.velocity[i]/self.dr
        
        self.jakobian[2*i,2*i+1] = self.rho[i]/self.dr
        
        # Jacobian for momentum equation on outer boundary
        self.jakobian[2*i+1,2*i-2] = -self.a**2/(self.rho[i]*self.dr)
        
        self.jakobian[2*i+1,2*i-1] = -self.velocity[i]/self.dr + self.x_cak* \
        self.alpha*(1./self.rho[i]*(self.velocity[i]-self.velocity[i-1]) \
        /(self.dr))**(self.alpha-1)*1./(self.rho[i]*self.dr)
        
        self.jakobian[2*i+1,2*i] = -self.a**2/self.rho[i]**2*(self.rho[i]- \
        self.rho[i-1])/(self.dr)+self.a**2/(self.rho[i]*self.dr)
        
        self.jakobian[2*i+1,2*i+1] = 2.*self.velocity[i]/self.dr-self.x_cak* \
        self.alpha*(1./self.rho[i]*(self.velocity[i]-self.velocity[i-1]) \
        /(self.dr))**(self.alpha-1)*1./(self.rho[i]*self.dr)
        
        return self.jakobian
    
    def split_phi(self):
        for i in range(self.resolution-1):
            self.rho = self.phi[2*i]
            self.velocity = self.phi[2*i+1]
        return
    
    def CAK_point_condition(self):
        grad = np.empty(self.resolution)*np.nan

        
        for i in range(self.resolution):
            grad[i] = self.x_cak*(1./self.rho[i]*self.dvdr[i])**self.alpha
        
        # Inner boundary
        self.cak_crit_condition[0] = self.velocity[0]-self.a**2/self.velocity[0] \
        - (grad[1]-grad[0])/(self.dvdr[1]-self.dvdr[1])
        
        for i in range(1,self.resolution-1):
            self.cak_crit_condition[i] = self.velocity[i]-self.a**2/self.velocity[i] \
            - (grad[i+1]-grad[i-1])/(self.dvdr[i+1]-self.dvdr[i-1])
            
        # Outer boundary 
        
        i = self.resolution-1
        self.cak_crit_condition[i] = self.velocity[i]-self.a**2/self.velocity[i] \
        -(grad[i]-grad[i-1])/(self.dvdr[i]-self.dvdr[i-1])
        
    def convergence_test(self,old):
        if old > 0:
            if linalg.norm(self.delta_phi)/old < 1.:
                convergence = True
            else:
                convergence = False
        else:
            convergence = False
        return convergence
        
    
    def inner_cycle(self):
        
        self.derivative()
        self.p_calculate()
        self.jakobian_calculate()
        inverse_jakobian = linalg.inv(self.jakobian)
        
        self.delta_phi = -np.dot(inverse_jakobian,self.p_operator_phi)
        self.phi = self.delta_phi + self.phi
        
        self.split_phi()
    
    def dimensionless_calcul(self,R,M,T):
        '''
        All units are in CGS
        '''
        
        R_star = R*Rs
        M_star = M*Ms
        T_star = T
        sig = sigma*1000
        L_star = 4.*np.pi*Rs**2*sig*T_star**4
        kappa_e_ref = 0.325
        k = 0.170
        v_th = np.sqrt(2.*kb*T_star/mp)
        self.Gamma = kappa_e_ref*L_star/(np.pi*4.*c*G*M_star)
        self.gm = G*M_star
        self.x_cak = kappa_e_ref*L_star*k/(4.*np.pi*c*v_th**self.alpha)
        mass_loss = 4.*np.pi/(kappa_e_ref*v_th)*((kappa_e_ref/4.*np.pi)*
        ((1.-self.alpha)/self.alpha)*(k*self.alpha)*L_star/c)**(1.0/self.alpha)* \
        self.gm*(1-self.Gamma)**(self.alpha-1.)/self.alpha
        self.velocity_infty = (2.*(self.gm*(1.-self.Gamma)*self.alpha/ \
        (1.-self.alpha)))**(self.beta)
        self.mass_conserve = 0.8*(mass_loss/(4.*np.pi))
        self.a = np.sqrt(k*T_star/mp)
        return
    
    def iterate(self):

        self.grid()
        self.dimensionless_calcul(37,90,28500)
        self.initial()
        
        iter = 0
        x = 0.5
        
        repeat_cycle = True
        
        # Before CAK point
        while (repeat_cycle):
            
            old_corrections_norm = linalg.norm(self.delta_phi)
            self.inner_cycle()
            convergence = self.convergence_test(old_corrections_norm)
            
            if np.all(self.cak_crit_condition < 0):
                self.rho_boundary = (1+x)*self.rho_boundary
                repeat_cycle = True
                
            elif np.any(self.cak_crit_condition > 0) or not(convergence):
                previous_rho_boundary = self.rho_boundary/(1+x)
                x = x/2.
                self.rho_boundary = (1+x)*self.rho_boundary
                repeat_cycle = True
                
            
            if np.abs(self.rho_boundary - previous_rho_boundary) < (self.rho_boundary/100.):
                repeat_cycle = False
        
            iter += iter
        
        # After CAK point
            
        return self.rho,self.velocity