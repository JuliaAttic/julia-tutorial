/* sor2d.c - Grid of Resistors problem in two dimensions */

/* MIT 18.337 - Applied Parallel Computing, Spring 2004  */
/* Per-Olof Persson <persson@math.mit.edu>               */

#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <time.h>

#define n 1000
#define niter 10

#define V(i,j) v[(i)+(2*n+1)*(j)]
#define SQR(x) ((x)*(x))

int main(int argc, char **argv)
{
  double mu,om;
  double *v;
  int it,i,j;

  printf("\nSize: n = %d\n\n",n);

  mu=0.5*(cos(M_PI/(2.0*n))+cos(M_PI/(2.0*n+1.0)));
  om=2.0*(1.0-sqrt(1.0-SQR(mu)))/SQR(mu);

  v=(double*)calloc((2*n+2)*(2*n+1),sizeof(double));

  int t1=clock();

  for (it=1; it<=niter; it++) {
    /* Update red nodes */
    for (j=1; j<2*n; j+=2) {
      for (i=1; i<2*n-2; i+=2) {
        V(i,j)=(1-om)*V(i,j)+om*0.25*(V(i+1,j)+V(i-1,j)+V(i,j+1)+V(i,j-1));
        V(i+1,j+1)=(1-om)*V(i+1,j+1)+om*0.25*(V(i+2,j+1)+V(i,j+1)+V(i+1,j+2)+V(i+1,j));
      }
      i=2*n-1;
      V(i,j)=(1-om)*V(i,j)+om*0.25*(V(i+1,j)+V(i-1,j)+V(i,j+1)+V(i,j-1));
    }
    /* RHS */
    V(n,n)+=om*0.25;
    
    /* Update black nodes */
    for (j=1; j<2*n; j+=2) {
      for (i=1; i<2*n-2; i+=2) {
        V(i,j+1)=(1-om)*V(i,j+1)+om*0.25*(V(i+1,j+1)+V(i-1,j+1)+V(i,j+2)+V(i,j));
        V(i+1,j)=(1-om)*V(i+1,j)+om*0.25*(V(i+2,j)+V(i,j)+V(i+1,j+1)+V(i+1,j-1));
      }
      i=2*n-1;
      V(i,j+1)=(1-om)*V(i,j+1)+om*0.25*(V(i+1,j+1)+V(i-1,j+1)+V(i,j+2)+V(i,j));
    }
    /* RHS */
    V(n,n+1)-=om*0.25;

    if (1) /* Change to 1 for printing (slower) */
      printf("Iter = %4d, r = %.16f\n",it,2*V(n,n));
  }

  int t2 = clock();
  
  printf("time per iter = %.5f r = %.5f\n\n", ((t2-t1)/(double)CLOCKS_PER_SEC)/niter, 2*V(n,n));

  free(v);
  return 0;
}
