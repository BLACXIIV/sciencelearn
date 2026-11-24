import { forwardRef, useState } from "react";
import { Icon } from "../../icons/Icon";
import { TextField, type TextFieldProps } from "../TextField/TextField";
import "../TextField/TextField.css";
import "./PasswordField.css";

/**
 * PasswordField — TextField with a show/hide eye toggle inside the input.
 * Toggle hit area is 44px. Pass autoComplete="current-password" or
 * "new-password" from the caller.
 */
export const PasswordField = forwardRef<HTMLInputElement, TextFieldProps>(function PasswordField(
  props,
  ref,
) {
  const [show, setShow] = useState(false);
  return (
    <TextField
      ref={ref}
      type={show ? "text" : "password"}
      trailing={
        <button
          type="button"
          className="ds-eye"
          aria-label={show ? "Hide password" : "Show password"}
          onClick={() => setShow((s) => !s)}
        >
          <Icon name={show ? "hide" : "show"} size={18} />
        </button>
      }
      {...props}
    />
  );
});
