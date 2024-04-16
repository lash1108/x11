import math
import x11, xlib, xkeyboard, xcursor, xutil, xdraw

type
  Point = tuple[x, y: float]
  ControlPoints = seq[seq[Point]]

proc binomialCoefficient(n, k: int): int =
  # Calcula el coeficiente binomial (n, k)
  if k < 0 or k > n:
    return 0
  if k == 0 or k == n:
    return 1
  result = 1
  for i in 0 .. min(k, n - k):
    result = result * (n - i) div (i + 1)

proc Bernstein(i, n: int, u: float): float =
  # Calcula el término de Bernstein para el parámetro u
  var coef: float = binomialCoefficient(n, i).float
  return coef * pow(u.float, i.float) * pow(1.0 - u, (n - i).float)

proc BezierSurface(u, v: float, controlPoints: ControlPoints): Point =
  # Calcula el punto en la superficie de Bézier para los parámetros u y v
  var result: Point
  result.x = 0.0
  result.y = 0.0
  let n = len(controlPoints) - 1
  let m = len(controlPoints[0]) - 1

  for i in 0..n:
    for j in 0..m:
      let bi = Bernstein(i, n, u)
      let bj = Bernstein(j, m, v)
      result.x += bi * bj * controlPoints[i][j].x
      result.y += bi * bj * controlPoints[i][j].y

  return result

# Configurar ventana X11
const width = 800
const height = 600
var display = XOpenDisplay(nil)
var screen = DefaultScreen(display)
var window = XCreateSimpleWindow(display, DefaultRootWindow(display), 0, 0, width, height, 0, 0, 0)
var gc = XCreateGC(display, window, 0, nil)

# Mapa de la ventana y manejo de eventos
XMapWindow(display, window)
while true:
  var event = XEvent()
  XNextEvent(display, addr event)

  if event.type == Expose and event.xexpose.count == 0:
    # Dibujar las curvas de Bézier
    let controlPoints: ControlPoints = @[
      @[(100.0, 100.0), (300.0, 200.0), (500.0, 100.0)],
      @[(100.0, 300.0), (300.0, 400.0), (500.0, 300.0)],
      @[(100.0, 500.0), (300.0, 600.0), (500.0, 500.0)]
    ]

    let segments = 100
    for i in 0 ..< segments:
      let u = i.float / segments.float
      var prevPoint = BezierSurface(u, 0.0, controlPoints)
      for j in 1 ..< segments:
        let v = j.float / segments.float
        let nextPoint = BezierSurface(u, v, controlPoints)
        XDrawLine(display, window, gc, prevPoint.x.int, prevPoint.y.int, nextPoint.x.int, nextPoint.y.int)
        prevPoint = nextPoint

  if event.type == KeyPress:
    break

# Limpiar y cerrar la ventana
XFreeGC(display, gc)
XDestroyWindow(display, window)
XCloseDisplay(display)
