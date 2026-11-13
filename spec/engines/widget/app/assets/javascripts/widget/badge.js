import confetti from 'canvas-confetti'

export function badge() {
  return typeof confetti === 'function' ? 'Hello from an engine' : 'missing confetti'
}
