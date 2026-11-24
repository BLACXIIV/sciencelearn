import { forwardRef } from "react";
import { Icon } from "../../icons/Icon";
import { TextField, type TextFieldProps } from "../TextField/TextField";
import "../TextField/TextField.css";
import "./SearchField.css";

/**
 * SearchField — TextField with a leading search icon and search semantics.
 * Use for filtering lists (students, classes, lessons).
 */
export const SearchField = forwardRef<HTMLInputElement, TextFieldProps>(function SearchField(
  props,
  ref,
) {
  return (
    <TextField
      ref={ref}
      type="search"
      leading={<Icon name="search" size={18} className="ds-field-lead" />}
      {...props}
    />
  );
});
