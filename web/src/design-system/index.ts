/* ScienceLearn Design System — single import surface.
   Pages must import ONLY from this barrel:
     import { Button, TextField } from "@/design-system";
   Token CSS is loaded as a side effect of importing this module. */

import "./tokens/base.css";
import "./tokens/colors.css";
import "./tokens/typography.css";
import "./tokens/radii.css";
import "./tokens/spacing.css";
import "./tokens/shadows.css";

/* tokens */
export { breakpoints } from "./tokens/breakpoints";

/* icons */
export { Icon } from "./icons/Icon";
export type { IconName, IconProps } from "./icons/Icon";

/* actions */
export { Button } from "./components/Button/Button";
export type { ButtonProps, ButtonVariant, ButtonSize } from "./components/Button/Button";
export { IconButton } from "./components/IconButton/IconButton";
export type { IconButtonProps } from "./components/IconButton/IconButton";

/* forms */
export { TextField } from "./components/TextField/TextField";
export type { TextFieldProps } from "./components/TextField/TextField";
export { PasswordField } from "./components/PasswordField/PasswordField";
export { TextArea } from "./components/TextArea/TextArea";
export type { TextAreaProps } from "./components/TextArea/TextArea";
export { Select } from "./components/Select/Select";
export type { SelectProps, SelectOption } from "./components/Select/Select";
export { Checkbox } from "./components/Checkbox/Checkbox";
export type { CheckboxProps } from "./components/Checkbox/Checkbox";
export { Switch } from "./components/Switch/Switch";
export type { SwitchProps } from "./components/Switch/Switch";
export { RadioCard } from "./components/RadioCard/RadioCard";
export type { RadioCardProps } from "./components/RadioCard/RadioCard";
export { RadioGroup } from "./components/RadioGroup/RadioGroup";
export type { RadioGroupProps, RadioGroupOption } from "./components/RadioGroup/RadioGroup";
export { SegmentedControl } from "./components/SegmentedControl/SegmentedControl";
export type { SegmentedControlProps } from "./components/SegmentedControl/SegmentedControl";
export { OptionTile } from "./components/OptionTile/OptionTile";
export type { OptionTileProps } from "./components/OptionTile/OptionTile";
export { SearchField } from "./components/SearchField/SearchField";
export { CodeInput } from "./components/CodeInput/CodeInput";
export { FileDropZone } from "./components/FileDropZone/FileDropZone";
export type { FileDropZoneProps } from "./components/FileDropZone/FileDropZone";
export type { CodeInputProps } from "./components/CodeInput/CodeInput";

/* surfaces */
export { Card } from "./components/Card/Card";
export type { CardProps, CardVariant, CardPastel } from "./components/Card/Card";
export { Panel } from "./components/Panel/Panel";
export type { PanelProps } from "./components/Panel/Panel";
export { BottomSheet } from "./components/BottomSheet/BottomSheet";
export type { BottomSheetProps } from "./components/BottomSheet/BottomSheet";
export { Modal } from "./components/Modal/Modal";
export type { ModalProps } from "./components/Modal/Modal";
export { Toast } from "./components/Toast/Toast";
export type { ToastProps, ToastTone } from "./components/Toast/Toast";

/* display */
export { Chip } from "./components/Chip/Chip";
export type { ChipProps, ChipVariant, ChipPastel } from "./components/Chip/Chip";
export { StickerBadge } from "./components/StickerBadge/StickerBadge";
export type { StickerBadgeProps } from "./components/StickerBadge/StickerBadge";
export { Badge } from "./components/Badge/Badge";
export type { BadgeProps, BadgeTone } from "./components/Badge/Badge";
export { ProgressBar } from "./components/ProgressBar/ProgressBar";
export type { ProgressBarProps, ProgressBarSize, ProgressBarTone } from "./components/ProgressBar/ProgressBar";
export { RingChart } from "./components/RingChart/RingChart";
export type { RingChartProps, RingSlice } from "./components/RingChart/RingChart";
export { StatCard } from "./components/StatCard/StatCard";
export type { StatCardProps } from "./components/StatCard/StatCard";
export { Avatar } from "./components/Avatar/Avatar";
export type { AvatarProps } from "./components/Avatar/Avatar";
export { EmptyState } from "./components/EmptyState/EmptyState";
export type { EmptyStateProps } from "./components/EmptyState/EmptyState";
export { Skeleton } from "./components/Skeleton/Skeleton";
export type { SkeletonProps } from "./components/Skeleton/Skeleton";
export { Divider } from "./components/Divider/Divider";
export type { DividerProps } from "./components/Divider/Divider";
export { ListItemCard } from "./components/ListItemCard/ListItemCard";
export type { ListItemCardProps } from "./components/ListItemCard/ListItemCard";
export { Thumbnail } from "./components/Thumbnail/Thumbnail";
export type { ThumbnailProps } from "./components/Thumbnail/Thumbnail";

/* quiz */
export { QuizOption } from "./components/QuizOption/QuizOption";
export type { QuizOptionProps, QuizOptionState } from "./components/QuizOption/QuizOption";
export { QuizCard } from "./components/QuizCard/QuizCard";
export type { QuizCardProps } from "./components/QuizCard/QuizCard";
export { QuizNav } from "./components/QuizNav/QuizNav";
export type { QuizNavProps } from "./components/QuizNav/QuizNav";
export { Flashcard } from "./components/Flashcard/Flashcard";
export type { FlashcardProps } from "./components/Flashcard/Flashcard";

/* layout */
export { PageHeader } from "./components/PageHeader/PageHeader";
export type { PageHeaderProps } from "./components/PageHeader/PageHeader";
export { PageSection } from "./components/PageSection/PageSection";
export type { PageSectionProps } from "./components/PageSection/PageSection";
export { AuthShell } from "./components/AuthShell/AuthShell";
export type { AuthShellProps } from "./components/AuthShell/AuthShell";
export { NavBar } from "./components/NavBar/NavBar";
export type { NavBarProps, NavItem, NavSection } from "./components/NavBar/NavBar";
export { IslandNavBar } from "./components/IslandNavBar/IslandNavBar";
export type { IslandNavBarProps } from "./components/IslandNavBar/IslandNavBar";
