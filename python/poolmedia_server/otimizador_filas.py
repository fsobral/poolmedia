import math
import numpy as np
import pandas as pd

from ortools.linear_solver import pywraplp

def otimizar_filas(hs,
                   vs,
                   hc,
                   vc,
                   m,
                   n,
                   dmin):
  #PAINEL DE CONTROLE
  #hs = 10 #largura da sala
  #vs = 7 #comprimento da sala

  #hc = 0.5 #largura da cadeira
  #vc = 0.5 #comprimento da cadeira

  hr = (hs-n*hc)/(n-1) #largura do corredor vertical
  vr = (vs-m*vc)/(m-1) #comprimento do corredor horizontal

  #dmin = 1 #ditancia minima entre pessoas

  #CALCULO DOS PARAMETROS
  cadeiras = []
  for j in range(m):
    for i in range(n):
      cadeira = {
          'id' : j*n+i,
          'fileira' : i+1,
          'cadeira' : j+1,
          'x' : i*(hs/n),   #coordenadas consideradas do canto superior
          'y' : j*(vs/m)    #esquerdo do retangulo de ocupacao do aluno
      }
      cadeiras.append(cadeira)
  #print(pd.DataFrame(cadeiras))

  #print("Tabela de nao adjacencia entre as cadeiras da sala:")
  nao_adjacencia = []
  for cadeira_l in cadeiras:
    for cadeira_k in cadeiras:
      if cadeira_l['id'] < cadeira_k['id']:
        if math.sqrt((cadeira_l['x']-cadeira_k['x'])**2+(cadeira_l['y']-cadeira_k['y'])**2) < dmin:
          nao_vizinho = {
              'id_cadeira_1' : cadeira_l['id'],
              'id_cadeira_k' : cadeira_k['id'],
              'distancia' : math.sqrt((cadeira_l['x']-cadeira_k['x'])**2+
                                      (cadeira_l['y']-cadeira_k['y'])**2)
          }
          nao_adjacencia.append(nao_vizinho)
  #print(pd.DataFrame(nao_adjacencia))


  # [START solver]
  # Create the mip solver with the CBC backend.
  solver = pywraplp.Solver('otimizacao_fileiras',
                            pywraplp.Solver.CBC_MIXED_INTEGER_PROGRAMMING)
  # [END solver]

  # [START variables]
  # x binary integer variable.
  x = {}
  for cadeira in cadeiras:
    x[cadeira['id']] = solver.BoolVar('x[%i]' % cadeira['id'])

  print('Numero de variaveis =', solver.NumVariables())
  # [END variables]

  # [START constraints]
  # x_{l}\cdot (1-\Delta_{l,k})\leq 1 - x_{k}
  for cadeira_l in cadeiras:
    for cadeira_k in cadeiras:
      if cadeira_l['id'] != cadeira_k['id']:
        if math.sqrt((cadeira_l['x']-cadeira_k['x'])**2+(cadeira_l['y']-cadeira_k['y'])**2) < dmin:
          solver.Add(x[cadeira_l['id']] + x[cadeira_k['id']] <= 1)

  print('Numero de restricoes =', solver.NumConstraints())
  # [END constraints]

  # [START objective]
  # Maximize \sum\limits_{l\in L}x_l
  solver.Maximize(solver.Sum(x[cadeira['id']] for cadeira in cadeiras))
  # [END objective]

  # [START solve]
  status = solver.Solve()
  # [END solve]

  # [START print_solution]
  if status == pywraplp.Solver.OPTIMAL:
      print('Solucao:')
      print('Funcao objetivo =', solver.Objective().Value())
      resposta = []
      for l in range(solver.NumVariables()):
        resposta.append(x[l].solution_value())
      resposta = np.reshape(resposta,(m,n))
      return {'status' : 1,
              'num_alunos' : solver.Objective().Value(),
              'num_fileiras' : n,
              'num_carteiras' : m,
              "largura_corredor_vertical": hr,
 	            "largura_corredor_horizontal": vr,
              'resposta' : resposta.T.tolist(),
              'tempo_resolucao' : solver.wall_time(),
              'num_iteracoes' : solver.iterations(),
              'num_nodes' : solver.nodes()}
  else:
      return {'status' : 0,
              'resposta':'O problema nao tem solucao otima.'}
  # [END print_solution]

  # [START advanced]
  #print('\nEstatistica de resolucao:')
  #print('Problema resolvido em %f milisegundos' % solver.wall_time())
  #print('Problema resolvido em %d iteracoes' % solver.iterations())
  #print('Problema resolvido em %d nos do branch-and-bound' % solver.nodes())
  # [END advanced]