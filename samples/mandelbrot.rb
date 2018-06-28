def print_density(d)
  if d > 8
    printf ' '
  elsif d > 4
    printf '.'
  elsif d > 2
    printf '*'
  else
    printf '+'
  end
end

def mandelconverger(real, imag, iters, creal, cimag)
  if iters > 255 || real*real + imag*imag >= 4
    iters
  else
    mandelconverger real*real - imag*imag + creal, 2*real*imag + cimag, iters + 1, creal, cimag
  end
end

def mandelconverge(real, imag)
  mandelconverger real, imag, 0, real, imag
end

def mandelhelp(xmin, xmax, xstep, ymin, ymax, ystep)
  y = ymin
  while y <= ymax
    x = xmin
    while x <= xmax
      print_density mandelconverge(x, y)
      x += xstep
    end
    printf "\n"
    y += ystep
  end
end

def mandel(realstart, imagstart, realmag, imagmag)
  mandelhelp realstart, realstart + realmag*78, realmag, imagstart, imagstart + imagmag*40, imagmag
end

mandel -2.3, -1.3, 0.05, 0.07

# i = 1
# while i < 1
#   mandel -2.3, -1.3, 0.05, 0.07
#   i += 1
# end
