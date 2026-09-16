import { fireEvent, render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it } from 'vitest'
import App from './App'

describe('Biggar Braai Shop', () => {
  beforeEach(() => localStorage.clear())

  it('filters stock by a customer search', () => {
    render(<App />)
    fireEvent.change(screen.getByLabelText(/search stock/i), { target: { value: 'lamb' } })

    expect(screen.getByText('Lamb Braai Chops')).toBeInTheDocument()
    expect(screen.queryByText('Premium Boerewors')).not.toBeInTheDocument()
  })

  it('gates restricted stock behind membership', () => {
    render(<App />)
    fireEvent.click(screen.getByLabelText('Unlock Dry-aged Ribeye'))

    expect(screen.getByRole('dialog', { name: /first pick/i })).toBeInTheDocument()
  })

  it('applies a 10% subscriber discount in the bag', () => {
    render(<App />)
    fireEvent.click(screen.getByText('Members save 10%'))
    fireEvent.click(screen.getByRole('button', { name: /start my membership/i }))
    fireEvent.click(screen.getByLabelText('Add Premium Boerewors to bag'))
    fireEvent.click(screen.getByLabelText(/shopping bag with 1 items/i))

    expect(screen.getByText('Inner Circle saving')).toBeInTheDocument()
    expect(screen.getAllByText(/116,99/).length).toBeGreaterThan(0)
  })
})
