c     Programa submultiplos.for


      implicit none

      integer numero, lin, col, i, j, k, ii, ini, kk, jopt, u,
     *  m1min, m1max, kkk
      integer mafil, macol, subdim, imenor, jmenor
      parameter (mafil=8500000, macol=20, subdim=100)
      integer solucion(macol), solopt(macol)
      integer matriz(mafil, macol), submu(subdim), numesub, filas
      integer columnas, noceros, numefail
      integer prede(mafil, macol)
      double precision costos(mafil, macol), cosopt, pobla
      double precision  p, q, cosmenor, cota, seed, probinf, parpul
      integer memfail, step, time, mejores, npobla, nparpul
      integer meritos(100, 20)
      double precision cosmeri(100), cant1, cant2, infe1, probanf
      double precision prind, cangru, totinfec, intes, sumtes 
      integer necepul, nparpu, nsteps, ntime, overf, nsumt
 
      integer longmer(100)


      write(*, *)' p:'
      read(*, *)p  

      write(*, *)' Poblacion total:'
      read(*, *) pobla

      write(*, *)' Parallel pools available:'
      read(*, *) parpul
 
      write(*, *)' Cuantas mejores estrategias deseas exponer?'
      write(*, *)' (100 como maximo por favor)'
      read(*, *) mejores
      if(mejores.gt.100) stop

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

      


c      seed = 282827213.

5      write(*, *)

c      write(*, *)' Comienzo de un nuevo test aleatorio' 

c      call rando(seed, p)
c      p = 0.3*p

      write(*, *)' p = ', p

       q = 1.d0 - p

c      cota = (dlog(3.d0)/3.d0)/dabs(dlog(q))

c      write(*, *)' Cota para m2 = ', cota

      cota =   1.464d0/dabs(dlog(q))          

      write(*, *)' Cota para m1 = ', 1.464d0/dabs(dlog(q)) 

      write(*, *)' Conta para m2 = ', 0.366/dabs(dlog(q))
      





      cosopt = 1.d30
      memfail = 0

      m1min = 2

      write(*, *)' m1 maximo permitido:'
      read(*, *) m1max

c      write(*, *)'m1min,  m1max = '
c      read(*, *) m1min, m1max


      do 4 numero = m1min, m1max   



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
      costos(1, 1) = 1./float(numero) + 1. - q**numero
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
      if(ini+kk.gt.mafil) then
      write(*, *)' Aumentar numero de filas mafil para mas de ', ini+kk
      write(25, *)' Falto memoria cuando m1 = ', numero
      memfail = memfail + 1
      numefail = numero
      go to 4
      endif
      filas = max0(filas, ini+kk)
      matriz(ini + kk, j) = submu(kk)
      prede(ini+kk, j) = k
      costos(ini+kk, j) = costos(k, j-1) + q**matriz(k, j-1)-
     *  q**matriz(ini+kk,j) + (1.-q**matriz(k, j-1))/matriz(ini+kk, j) 
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
      do i = 1, filas
      if(matriz(i, j).ne.0.and.costos(i, j).lt.cosmenor) then
      cosmenor = costos(i, j)
      imenor = i
      jmenor = j
      endif
      end do
      end do

      write(*, *)' Resultado para p=:', p, ' m1 =', numero  
      write(27, *) numero, cosmenor

      write(*, *)' Costo para estos valores de p y m1:', cosmenor
c      write(*, *)' imenor, jmenor =', imenor, jmenor 

      i = imenor
      do j = jmenor, 1, -1
      solucion(j) = matriz(i, j)
      i = prede(i, j)
      end do  

      write(*, *)' Solucion para p=:', p, ' m1 =', numero

      do i = 1, jmenor
      write(*, *) solucion(i)
      end do
      do i = 1, jmenor-1
      write(*, *)' Cociente entre m(j) y m(j+1) = ', 
     *  solucion(i)/solucion(i+1)
      end do
      write(*, *)

      write(29, *)' Solucion para p=:', p, ' m1 =', numero
      do i = 1, jmenor
      write(29, *) solucion(i)
      end do
      do i = 1, jmenor-1
      write(29, *)' Cociente entre m(j) y m(j+1) = ', 
     *  solucion(i)/solucion(i+1)
      end do
      write(29,*) 
      write(29, *)



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


      write(*, *)
      write(*, *)' Solucion final para  p = ', p

      write(*, *)' Longitud de la estrategia:', jopt     

      do i = 1, jopt
      write(*, *) solopt(i)
      end do


c        write(*, *)' 1/m1 + 1 - q^m1 = ',
c     *   1.d0/solopt (1) + 1.d0 - (1.d0-p)**solopt(1)
 
 


      write(*, *)' Optimal cost :', cosopt
      write(*, *)' Failuress by lack of memory:', memfail
      
c      write(*, *)' Limitante inferior: ', 1.d0/solopt(1)
c
c
c
      write(*, *)'*************************************************'
      write(*, *)
      npobla = pobla
      write(*, *)' Population :', npobla,' p = ', p
      nparpul = parpul
      write(*, *)' Parallel pools available:',nparpul  
      write(*, *)' Maximum pool-size allowed (m1):', m1max          
      write(*, *)'*************************************************'
      write(*, *) ' Best ', mejores,' strategies for p = :', p
      do i = 1, mejores
      write(*, *)'        ***************************************' 
      write(*, *)
      if(i.eq.1) write(*, *) ' 1-st best strategy'
      if(i.eq.2) write(*, *) ' 2-nd best strategy'  
      if(i.eq.3) write(*, *) ' 3-rd best strategy'  
 
      if(i.gt.3)  write(*, *) i, '-th   Best strategy ' 
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
      cangru = pobla/meritos(i, 1)
      
c  cangru es el numero de grupos en el nivel 1

      sumtes = 0.d0
      ntime = 0 
      
      do j = 1, longmer(i)

      write(*, *)
      write(*, *)' Stage ', j,' Size of each pool:', meritos(i,j)
      necepul = cangru + 1.
      write(*, *)' Number of Pools that are necessary for this stage:',
     *   necepul
      nparpu = parpul
      overf = mod(necepul, nparpu)
      nsteps = (necepul - overf)/parpul + 1
      write(*, *)' Time units necessary to process this stage:', nsteps
      write(*, *)' including 1 time unit for an overflow equal to ', 
     *  overf,' pools '
      ntime = ntime + nsteps
      write(*, *)' Accumulated time up to this stage:', 
     *  ntime,' time units' 

     
                          

      
c      write(*, *)' Number of tests at stage  ', j,' = ', 
c     *   cangru

c  compute the number of time steps for this stage considering parallelism
c      step = cangru/parpul + 1.d0
c      time = time + step
c      write(*, *)' Time steps at stage ', j,' considering parallelism:'
c     *,   step, ' Accumulated:', time
      


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
      necepul = cangru + 1.
      write(*, *)' Pools that are necessary for this stage:', necepul
      nparpu = parpul
      overf = mod(necepul, nparpu)
      nsteps = (necepul - overf)/parpul + 1
      write(*, *)' Time units necessary to process this stage:', nsteps
      write(*, *)' including 1 time unit for an overflow equal to = ',
     *   overf, ' pools'
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


      

  
      write(29, *)
      write(29, *)' Fallas por falta de memoria:',  memfail 
      write(29, *)' Solucion final para  p = ', p
      write(29, *)' Longitud de la estrategia:', jopt     
  

  
      do i = 1, jopt
      write(29, *) solopt(i)
      end do
      write(29, *)' Costo optimo:', cosopt
 

      stop
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
             
 