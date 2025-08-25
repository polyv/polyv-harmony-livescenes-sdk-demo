import { PLVHashMap } from '@polyvharmony/live-scenes-sdk'

export type PlayStatus = "live" | "stop" | "end" | "playback" | "unStart" | "waiting"

export type DialogName = "default" | "desc" | "previous"

export class PLVLWCommonDef {
  static readonly STATUS_COLOR_MAP: PLVHashMap<PlayStatus, ResourceColor> = new PLVHashMap<PlayStatus, ResourceColor>()
    .set("live", $r('app.color.plvlw_function_color_red'))
    .set("stop", $r('app.color.plvlw_function_color_green'))
    .set("end", $r('app.color.plvlw_neutral_dark_white_80'))
    .set("playback", $r('app.color.plvlw_theme_bg_blue'))
    .set("unStart", $r('app.color.plvlw_function_color_green'))
    .set("waiting", $r('app.color.plvlw_function_color_green'))
  static readonly STATUS_BG_COLOR_MAP: PLVHashMap<PlayStatus, ResourceColor> = new PLVHashMap<PlayStatus, ResourceColor>()
    .set("live", $r('app.color.plvlw_function_color_red_10'))
    .set("stop", $r('app.color.plvlw_function_color_green_10'))
    .set("end", $r('app.color.plvlw_neutral_light_black_10'))
    .set("playback", $r('app.color.plvlw_theme_bg_blue_10'))
    .set("unStart", $r('app.color.plvlw_function_color_green_10'))
    .set("waiting", $r('app.color.plvlw_function_color_green_10'))
  static readonly STATUS_TEXT_MAP: PLVHashMap<PlayStatus, ResourceStr> = new PLVHashMap<PlayStatus, ResourceStr>()
    .set("live", $r('app.string.plvlw_live_state_live'))
    .set("stop", $r('app.string.plvlw_live_state_stop'))
    .set("end", $r('app.string.plvlw_live_state_end'))
    .set("playback", $r('app.string.plvlw_live_state_playback'))
    .set("unStart", $r('app.string.plvlw_live_state_un_start'))
    .set("waiting", $r('app.string.plvlw_live_state_waiting'))
  static readonly BACK_PRIORITY_IFRAME_TAB_CONTENT: number = 4998
  static readonly BACK_PRIORITY_TEXT_TAB_CONTENT: number = 4999
  static readonly BACK_PRIORITY_DESC_TAB_CONTENT: number = 5000
  static readonly BACK_PRIORITY_CHAT_INPUT = 10000
  static readonly BACK_PRIORITY_INTERACT_LAYOUT: number = 30000
  static readonly BACK_PRIORITY_GLOBAL_DIALOG: number = 100000
  static readonly BACK_PRIORITY_GLOBAL_DIALOG_DESC_TAB: number = 100001
  // 对于弹窗里面的内容，如弹窗里的web组件的返回，其优先级比全局弹窗高
  static readonly BACK_PRIORITY_GLOBAL_DIALOG_DESC_TAB_CONTENT: number = 100002
  static readonly BACK_PRIORITY_GLOBAL_DIALOG_PREVIOUS: number = 100011
}