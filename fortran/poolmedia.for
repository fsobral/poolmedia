c  programa poolmedia.for. Basado en submultiplos.for
c  Minimizar el costo considerando un intervalo de incerteza
c  en la probabilidad.
c  Actualizado en 6 enero 2021.

      implicit none

      integer numero, lin, col, i, j, k, ii, ini, kk, jopt, u,
     *  m1min, m1max, kkk, jj, diez
      integer mafil, macol, subdim, imenor, jmenor
      parameter (mafil=8500000, macol=20, subdim=100)
      integer solucion(macol), solopt(macol)
      integer matriz(mafil, macol), submu(subdim), numesub, filas
      integer columnas, noceros, numefail
      integer prede(mafil, macol)
      double precision costos(mafil, macol), cosopt, acum
      double precision  p, q, cosmenor, cota, seed, probinf, parpul
      integer memfail, step, time, mejores, npobla, nparpul
      integer meritos(100, 20), pobla, ncang
      double precision cosmeri(100), cant1, cant2, infe1, probanf
      double precision prind, cangru, totinfec, intes, sumtes, nbomax 
      integer necepul, nparpu, nsteps, ntime, overf, nsumt,kmax1,nbon
      integer pseudo, filused
      integer longmer(100)

      character*200 file

      double precision pmin, pmax

      diez = 10
      filused = 0

      write(*, *)' Name of the output file:'
      read(*, *) file
      open (20,file=file)

      write(*, *)
     * ' Minimal and maximal probability of individual infection:'
      read(*, *)pmin, pmax
      if(pmin.gt.pmax) then
         write(*, *)' Sorry: Minimal cannot be bigger than maximum. '
         write(20, 9000) 'Minimal cannot be bigger than maximum.'
         goto 7000
      endif
      if(pmin.eq.pmax) then
      diez = 0
      p = pmin
      q = 1.d0-p
      endif
 


      if(pmax.gt.0.3066387) then
         write(*, *)' It seems that you believe that the probability '
         write(*, *)' of infection may be bigger than 0.3066387.'
         write(*, *)' In that case, the  optimal solution is to test '
         write(*, *)' all the individuals immediately.'
         write(*, *)' The average cost is equal to 1 and we stop here.'

         write(20,9000)
     + ' It seems that you believe that the probability
     +  of infection may be bigger than 0.3066387.
     +  In that case, the  optimal solution is to test
     +  all the individuals immediately.
     +  The average cost is equal to 1 and we stop here.'
         
         goto 7000
      endif  

      write(*, *)' How many best strategies do you want to report ?'
      write(*, *)' (No more than 100 please)'
      read(*, *) mejores
      if(mejores.gt.100) then
         write(*, *)' Sorry, we dont admit more than 100. We stop here.'
         write(20, 9000) 'Sorry, we dont admit more than 100.'
         goto 7000
      endif                 

 


c  Inicializar matriz de méritos
      do j = 1, 20 
      do i = 1, mejores 
      meritos(i, j) = 0
      end do
      end do
      do i = 1, mejores
      cosmeri(i) = 10.d0
      longmer(i) = 20 
      end do

      



5      write(*, *)





c      cota = (dlog(3.d0)/3.d0)/dabs(dlog(q))

c      write(*, *)' Cota para m2 = ', cota

      nbomax =   1.464d0/dabs(dlog(1.d0-pmin)) + 1.d0  
 
      nbon = nbomax

      if(nbon.gt.0) then
      write(*, *)' Bound for optimal m(1) = ', nbon 
      else
      write(*, *)' Bound for optimal m(1) = ', nbomax
      endif

      nbomax =    0.366/dabs(dlog(1.d0-pmin)) + 1.d0  
      nbon = nbomax
      if(nbon.gt.0) then
      write(*, *)' Bound for optimal m(2) = ', nbon
      else
      write(*, *)' Bound for optimal m(2) = ', nbomax
      endif

     
 



      cosopt = 1.d30
      memfail = 0

      m1min = 2

      write(*, *)' Maximal allowed value for m(1) (first pool size):'
      write(*, *)' (Computer time depends on this number.'
      write(*, *)' You can expect that time = m1/1000 minutes'
      write(*, *)' You can set m1 greater than "Bound for optimal m(1)"'
      write(*, *)' if you are interested in suboptimal.)'
      write(*, *)' strategies.'

      read(*, *) m1max

      write(*, *)' Maximum number of stages k+1:'
      read(*, *) kmax1



      do 4 numero = m1min, m1max   

c888888888888888888888888888888888888888888888888888888888888888888888888888888888
c     Impresiones (*, *) a partir de aqui y hasta el lugar indicado tienen importancia
c     interna y son irrelevantes para el usuario
c888888888888888888888888888888888888888888888888888888888888888888888888888888888

      write(*, *)
      write(*, *)
     *  ' m1 = ', numero, ' m1 minimo:', m1min,' m1 maximo:', m1max       

      do j = 1, macol
      do i = 1, mafil
      matriz(i, j) = 0
      prede(i, j) = 0
      end do
      end do

      filas = 0
      columnas = 0
 
      matriz(1, 1) = numero

      acum = 0.d0
      if(pmin.eq.pmax) then
      acum = 1.d0/float(numero) + 1. - q**numero  
      else 

      do jj = 1, diez+1
      p = pmin + dfloat(jj-1)/dfloat(diez) *(pmax-pmin)
      q = 1.d0 -  p
      acum = acum + 1.d0/float(numero) + 1. - q**numero
      end do
      endif
      costos(1, 1) = acum/dfloat(diez+1)



      do 1 j = 2, macol

c   Verificar si la columna j-1 tenia no-ceros
      noceros=0
      do i = 1, mafil
      noceros = noceros + matriz(i, j-1)
      end do
      if(noceros.eq.0) go to 3


      
      ini = 0
      do 2 k = 1, mafil
      if(matriz(k, j-1).eq.0) go to 1
      if(matriz(k, j-1).eq.1) go to 2
c      write(*, *)' matriz(k, j-1)=', matriz(k, j-1)
      call submultiplos(matriz(k, j-1), submu, numesub)
c      write(*, *)' Submultiplos de ', matriz(k, j-1),' hay ', numesub
      do kk = 1, numesub
      filused = max0(filused, ini+kk)
      if(ini+kk.gt.mafil) then
      write(*, *)' Aumentar numero de filas mafil para mas de ', ini+kk
      write(*, *)' Falto memoria cuando m1 = ', numero
      memfail = memfail + 1
      numefail = numero
      go to 4
      endif
      filas = max0(filas, ini+kk)
      matriz(ini + kk, j) = submu(kk)
      prede(ini+kk, j) = k

      acum = 0.d0
      if(pmin.eq.pmax) then
      acum =  q**matriz(k, j-1)-
     *  q**matriz(ini+kk,j) + (1.-q**matriz(k, j-1))/matriz(ini+kk, j)  
      else 

      do jj = 1, diez+1
      p = pmin + dfloat(jj-1)/dfloat(diez) *(pmax-pmin)
      q = 1.d0 -  p
      acum = acum +  q**matriz(k, j-1)-
     *  q**matriz(ini+kk,j) + (1.-q**matriz(k, j-1))/matriz(ini+kk, j) 
      end do
      endif

      costos(ini+kk, j) = costos(k, j-1) + acum/dfloat(diez+1)





      end do     
      ini = ini + numesub
2     continue

1     continue 

3      columnas = j-1

      write(*, *)' Numero de filas necesarias para la matriz:', filas
      write(*, *)' Numero columnas necesarias para la matriz:', columnas
c      write(*, *)' Matriz de divisores:'
c      write(*, *)'         Fila'
c      do i = 1, filas 
c      write(*, *)i, (matriz(i, j),j=1,columnas)
c      end do   

c     write(*, *)' Matriz de predecesores:'
c      write(*, *)'         Fila'
c      do i = 1, filas 
c      write(*, *)i, (prede(i, j),j=1,columnas)
c      end do 

c      write(*, *)' Matriz de costos:'  
c      write(*, *)'         Fila'
c      do i = 1, filas 
c      write(*, *)i, (costos(i, j),j=1,columnas)
c      end do 
  

c      write(*, *)' Numero de filas necesarias para la matriz:', filas
c      write(*, *)' Numero columnas necesarias para la matriz:', columnas   

c  Encontrar el menor costo
      cosmenor = costos(1, 1)
      imenor = 1
      jmenor = 1
      do j = 1, columnas
      if(j.le.kmax1-1) then
      do i = 1, filas
      if(matriz(i, j).ne.0.and.costos(i, j).lt.cosmenor) then
      cosmenor = costos(i, j)
      imenor = i
      jmenor = j
      
      endif
      end do
      endif
      end do

      write(*, *)' Resultado para  m1 =', numero  

      write(*, *)' Costo para este  m1:', cosmenor

      i = imenor
      do j = jmenor, 1, -1
      solucion(j) = matriz(i, j)
      i = prede(i, j)
      end do  

      write(*, *)' Solucion para  m1 =', numero

      do i = 1, jmenor
      write(*, *) solucion(i)
      end do
      do i = 1, jmenor-1
      write(*, *)' Cociente entre m(j) y m(j+1) = ', 
     *  solucion(i)/solucion(i+1)
      end do
      write(*, *)




c  Poner la ultima solucion obtenida en su orden de mérito

      do i = 1, mejores
        if(cosmenor.lt.cosmeri(i)) then
          do ii = mejores, i+1, -1
            cosmeri(ii) = cosmeri(ii-1)
            longmer(ii) = longmer(ii-1)
            do j = 1, longmer(ii)
            meritos(ii, j) = meritos(ii-1, j)
            end do
          end do
            cosmeri(i) = cosmenor
            longmer(i) = jmenor
            do j = 1, jmenor
            meritos(i, j) = solucion(j)
            end do
         go to 6
        endif
      end do

6      if(cosmenor.lt.cosopt) then
      cosopt = cosmenor
      jopt = jmenor
      do i = 1, jopt
      solopt(i) = solucion(i)
      end do
      endif
      write(*, *)' Costo minimo hasta ahora obtenido en m1 =', solopt(1)
      write(*, *)' con un costo igual a ', cosopt
 

4     continue
c   Este "4 continue" corresponde a "do 4 m1 = m1min, m1max"
c   O sea, aqui termina el proceso de optimizacion, arrojando la solucion solopt. 





      write(*, *)
      write(*, *)' Solucion final: '

      write(*, *)' Longitud de la estrategia:', jopt     

      do i = 1, jopt
      write(*, *) solopt(i)
      end do


c8888888888888888888888888888888888888888888888888888888888888888888888888888888888
c    A partir de aqui las impresiones vuelven a tener importancia para el usuario
c8888888888888888888888888888888888888888888888888888888888888888888888888888888888
 


      write(*, *)' Number of rows used:', filused,' over a maximum of '
     *,  mafil


 


      write(*, *)' Optimal cost :', cosopt
      write(*, *)' Failures by lack of memory:', memfail
      write(*, *)' Solution:'
      write(*, *)(solopt(i),i=1,jopt)
      write(*, *)' Optimal cost:', cosopt
      write(*, *)' End of Optimization'
      write(*, *)'*************************************************'

      do i = 1, mejores
      write(*, *)'*************************************************' 
      write(*, *)
      if(meritos(i, 1).eq.0) then
      write(*, *)' The number of feasible strategies is smaller than ',
     *   mejores
      stop
      endif


      if(i.eq.1) write(*, *) '          1 -st best strategy'
      if(i.eq.2) write(*, *) '          2 -nd best strategy'  
      if(i.eq.3) write(*, *) '          3 -rd best strategy'  
 
      if(i.gt.3)  write(*, *) i, '-th   best strategy ' 
      write(*, *)' Number of stages (k+1):', longmer(i)+1
      write(*, *)' Sequence  m1, m2, ..., mk, m_{k+1} :' 
      write(*, *) (meritos(i,j),j=1,longmer(i)), '        1 '
      write(*, *)' Cost of this sequence = ', cosmeri(i)
      write(*, *)
      
      end do

 


      write(*, *)'*************************************************'
 

      write(*, *)' If you want pseudo-simulations considering '
      write(*, *)' parallel pools availability, type 1'
      write(*, *)' otherwise, type 0'
      read(*, *) pseudo

      write(*, *)'*************************************************'

      if(pseudo.eq.0) stop

      write(*, *)' Total population:'
      read(*, *) pobla

      write(*, *)' Parallel pools available:'
      read(*, *) parpul





      write(*, *)
      p = (pmin+pmax)/2.d0

      write(*, *)' Population :', pobla,' p = ', p
      nparpul = parpul
      write(*, *)' Parallel pools available:',nparpul  

      write(*, *)' Maximum pool-size allowed (m1):', m1max          
      write(*, *)'*************************************************'
      write(*, *) ' Best ', mejores,' strategies :' 

      write(*, *)' (For simulating stages we use p =', p,' .)' 
      write(*, *)'  Pseudosimulations are not real simulations'
      write(*, *)'  of the testing process. Take then as a rough'
      write(*, *)'  indication of real possibilities.'
      
      do i = 1, mejores
      write(*, *)'        ***************************************' 
      write(*, *)
      if(meritos(i, 1).eq.0) then
      write(*, *)' The number of feasible strategies is smaller than ',
     *   mejores
      stop
      endif

      write(*, *)' Pseudo-simulation of '

      if(i.eq.1) write(*, *) '          1 -st best strategy'
      if(i.eq.2) write(*, *) '          2 -nd best strategy'  
      if(i.eq.3) write(*, *) '          3 -rd best strategy'  
 
      if(i.gt.3)  write(*, *) i, '-th   best strategy ' 
      write(*, *)' Number of stages (k+1):', longmer(i)+1
      write(*, *)' Sequence  m1, m2, ..., mk, m_{k+1} :' 
      write(*, *) (meritos(i,j),j=1,longmer(i)), '        1 '
      write(*, *)' Cost of this sequence = ', cosmeri(i)
      write(*, *)
      


c**************************************************************************
c  totinfec es el numero total de infectados en la poblacion

c  prind es la probabilidad de que un individuo envuelto en los tests
c  de determinado nivel j esté infectado
c  En el nivel 1 es igual a p

      totinfec = p * pobla   

c      write(*, *)' Total de infectados en la poblacion:', totinfec       

      prind = p
      cangru = dfloat(pobla)/dfloat(meritos(i, 1))
      
c  cangru es el numero de grupos en el nivel 1

      sumtes = 0.d0
      ntime = 0 
      
      do j = 1, longmer(i)

      write(*, *)
      write(*, *)' Stage ', j,' Size of each pool:', meritos(i,j)
      
      ncang = cangru
      if(cangru.gt.dfloat(ncang)) then
      necepul = cangru + 1.
      else
      necepul = cangru
      endif

      write(*, *)' Number of Pools that are necessary for this stage:',
     *   necepul
      nparpu = parpul
      overf = mod(necepul, nparpu)
      if(overf.eq.0) then
      nsteps = (necepul-overf)/parpul
      else
      nsteps = (necepul - overf)/parpul + 1
      endif
      write(*, *)' Time units necessary to process this stage:', nsteps
      if(nsteps.gt.1) then
      if(overf.ne.0) then
      if(overf.eq.1) then
      write(*, *)' including 1 time unit for an overflow equal to ', 
     *  overf,' pool '
      else
      write(*, *)' including 1 time unit for an overflow equal to ', 
     *  overf,' pools '       
      endif
      endif
      endif
      ntime = ntime + nsteps
      write(*, *)' Accumulated time up to this stage:', 
     *  ntime,' time units' 

     
                          

      


      sumtes = sumtes + cangru

c  Calcular la probabilidad de que un grupo en el nivel j
c  (cuyo numero de miembros es meritos(i, j))
c  tenga algun individuo infectado
      probinf = 1.d0 - (1.d0-prind)**meritos(i, j)

c      write(*, *)' Probabilidad de que um grupo en  nivel ', j
c      write(*, *)' (con ', meritos(i, j),' individuos', ' )'
c      write(*, *)' esté infectado:', probinf


c  Calcular la cantidad de grupos infectados en el nivel j 
      infe1 = probinf * cangru 
c      write(*, *)' Cantidad de grupos infectados en el nivel', j,'=',
c     *  infe1 
   
c  Calcular la cantidad de grupos en el nivel j+1
      cangru = infe1*meritos(i, j)

      if(j.lt.longmer(i)) then 
      cangru = cangru/meritos(i, j+1)

c      write(*, *)' Cantidad de grupos en el nivel ', j+1,' = ', cangru      
c  Calcular la cantidad de individuos envueltos en tests en el nivel j+1
      intes = cangru * meritos(i, j+1)

c      write(*, *)' Total individuos envueltos en tests en nivel',
c     *   j+1,' = ',intes
c  Calcular la probabilidad de que un individuo envuelto em tests en el 
c  nivel j+1 este' infectado
      prind = totinfec/intes

c      prind = p
c      write(*, *)' Probabilidad de que un individuo envuelto en tests'
c      write(*, *)' en el nivel ', j+1,' esté infectado:', prind
      endif
      end do 

      sumtes = sumtes + cangru
      write(*, *)
      write(*, *)' Stage ', longmer(i)+1 ,' Size of each pool: 1'

      ncang = cangru
      if(cangru.gt.dfloat(ncang)) then
      necepul = cangru + 1.
      else
      necepul = cangru
      endif

      write(*, *)' Pools that are necessary for this stage:', necepul
      nparpu = parpul
      overf = mod(necepul, nparpu)
      if(overf.eq.0) then
      nsteps = (necepul-overf)/parpul
      write(*, *)' Time units necessary to process this stage:', nsteps      
      else
      nsteps = (necepul - overf)/parpul + 1
      write(*, *)' Time units necessary to process this stage:', nsteps
      if(nsteps.gt.1) then
      if(overf.eq.1) then
      write(*, *)' including 1 time unit for an overflow equal to = ',
     *   overf, ' pool'
      else
      write(*, *)' including 1 time unit for an overflow equal to = ',
     *   overf, ' pools'        
      endif
      endif
      endif
      ntime = ntime + nsteps

c      write(*, *)' Number of (individual) tests at stage ',
c     *    longmer(i)+1,' :', cangru 
c      sumtes = sumtes + cangru
c      step = cangru/parpul + 1.d0
c      time = time + step
c      write(*, *)' Time steps at stage ', j,' considering parallelism:'
c     *,   step, ' Accumulated:', time
 
      nsumt = sumtes+1.d0
      write(*, *)' Total number of tests:', nsumt                    
      write(*, *)' Total number of tests / population:', sumtes/pobla

      write(*, *)' Accumulated time of the whole strategy:',
     *   ntime,' time units' 
 
 

      write(*, *) 
c*******************************************************************************
      end do


 7000 close(20)
      stop

C     JSON error format
 9000 FORMAT('{',/,
     +     2X,'found_solution: false,',/,
     +     2X,'message: "',A,'"',/,
     +     '}')


      end

      subroutine submultiplos(numero, submu, numesub)
      implicit none
      integer numero
      integer submu(numero), numesub
      integer i, j, k

c      write(*, *)' Entrada a subrout submultiplos, numero:', numero

      if(numero.eq.1) then
      numesub = 0
      return
      endif

      i = dfloat(numero)/2.d0+0.8
      k = 0
      do j = i, 1, -1
      if(mod(numero, j).eq.0) then
      k = k+1
      submu(k) = j
      endif
      end do
      numesub = k
      return
      end





                       
      subroutine rando(seed, x)

C     This is the random number generator of Schrage:
C
C     L. Schrage, A more portable Fortran random number generator, ACM
C     Transactions on Mathematical Software 5 (1979), 132-138.

      double precision seed, x 

      double precision a,p,b15,b16,xhi,xalo,leftlo,fhi,k
      data a/16807.d0/,b15/32768.d0/,b16/65536.d0/,p/2147483647.d0/

      xhi= seed/b16
      xhi= xhi - dmod(xhi,1.d0)
      xalo= (seed-xhi*b16)*a
      leftlo= xalo/b16
      leftlo= leftlo - dmod(leftlo,1.d0)
      fhi= xhi*a + leftlo
      k= fhi/b15
      k= k - dmod(k,1.d0)
      seed= (((xalo-leftlo*b16)-p)+(fhi-k*b15)*b16)+k
      if (seed.lt.0) seed = seed + p
      x = seed*4.656612875d-10

      return

      end 
