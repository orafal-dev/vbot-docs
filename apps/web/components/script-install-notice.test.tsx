import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import { ScriptInstallNotice } from "./script-install-notice"

describe("ScriptInstallNotice", () => {
  it("explains where to install downloaded scripts", () => {
    render(<ScriptInstallNotice />)

    expect(
      screen.getByLabelText("Script installation instructions")
    ).toBeInTheDocument()
    expect(screen.getByText("Where to install this script")).toBeInTheDocument()
    expect(
      screen.getByText(
        "%localappdata%\\ValidusBot\\Products\\tibia\\UserData\\Scripts"
      )
    ).toBeInTheDocument()
  })
})
