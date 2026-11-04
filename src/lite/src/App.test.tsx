import { describe, it, expect, afterEach } from 'vitest'
import { render, screen, cleanup } from '@testing-library/react'
import '@testing-library/jest-dom/vitest'
import App from './App'

// 冒烟测试：首屏必须渲染出内容。白屏（坏 import、渲染期崩溃）会在这里失败。
describe('页面渲染冒烟', () => {
  it('渲染轻量端首屏', () => {
    window.history.pushState({}, '', '/')
    render(<App />)
    expect(screen.getByRole('heading', { name: '量潮产品云 Lite' })).toBeInTheDocument()
    expect(screen.getByText(/量潮产品云轻量端/)).toBeInTheDocument()
  })
})

afterEach(cleanup)
