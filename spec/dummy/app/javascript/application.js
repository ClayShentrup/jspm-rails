import TomSelect from 'tom-select'
import { greeting } from './greeting.js'
import { badge } from 'widget/badge'
import { theme } from 'settings'

document.getElementById('greeting').textContent = greeting
document.getElementById('badge').textContent = badge()
document.getElementById('theme').textContent = theme
new TomSelect('#flavor')

const lazyName = ['lazy', 'hello'].join('/')
const { message } = await import(lazyName)
document.getElementById('lazy').textContent = message

const { default: katex } = await import('katex')
katex.render('e^{i\\pi} + 1 = 0', document.getElementById('formula'))
