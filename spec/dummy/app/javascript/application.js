import TomSelect from 'tom-select'
import { greeting } from './greeting.js'

document.getElementById('greeting').textContent = greeting
new TomSelect('#flavor')

const { default: katex } = await import('katex')
katex.render('e^{i\\pi} + 1 = 0', document.getElementById('formula'))
