import {
  IPLVCanReplyEvent,
  PLVChatImgEvent,
  PLVChatPlaybackDataVO,
  PLVChatQuoteDataBean,
  PLVCommonConstants,
  PLVEmotionEvent,
  PLVHistoryChatImgEvent,
  PLVHistoryFileShareEvent,
  PLVHistorySpeakEvent,
  PLVLocalQuizEvent,
  PLVLocalSpeakEvent,
  PLVRedPaperEvent,
  PLVSpeakEvent,
  PLVTAnswerEvent,
  PLVTextUtils,
  PLVUserType
} from '@polyvharmony/live-scenes-sdk'
import { LengthUnit } from '@kit.ArkUI'
import { extendNumber, isTextBlank, lateInit } from '@polyvharmony/media-player-sdk'
import { PLVLWFaceManager } from '../../../../common/PLVLWFaceManager'

@Component
export struct PLVLWChatContentItemSpeakContent {
  avatar?: ResourceStr
  actor?: string
  actorColorForeground?: ResourceColor
  actorColorBackground?: ResourceColor
  nick?: string
  nickColor?: ResourceColor
  speakMessage?: string
  speakMessageColor?: ResourceColor
  maxLines: number = Number.MAX_SAFE_INTEGER

  build() {
    Text() {
      if (this.avatar) {
        ImageSpan(this.avatar)
          .verticalAlign(ImageSpanAlignment.CENTER)
          .margin({
            right: 2
          })
          .size({
            width: 16,
            height: 16
          })
          .borderRadius(16)
      }

      if (this.actor) {
        Span(`  ${this.actor}  `)
          .fontSize(9)
          .fontColor(this.actorColorForeground)
          .textBackgroundStyle({
            color: this.actorColorBackground,
            radius: 8
          })
          .baselineOffset({
            value: 2,
            unit: LengthUnit.FP
          })

        Span('  ').fontSize(9)
      }
      if (this.nick) {
        Span(`${this.nick}:`)
          .fontSize(14)
          .fontColor(this.nickColor)

        Span('  ').fontSize(9)
      }
      if (this.speakMessage) {
        ForEach(
          PLVTextUtils.parseString(this.speakMessage),
          (parsed: string) => {
            if (!PLVLWFaceManager.hasFace(parsed)) {
              Span(parsed)
                .fontSize(14)
                .fontColor(this.speakMessageColor)
            } else {
              ImageSpan(PLVLWFaceManager.getFace(parsed))
                .width(18)
                .height(18)
                .verticalAlign(ImageSpanAlignment.CENTER)
            }
          }
        )
      }
    }
    .align(Alignment.Center)
    .maxLines(this.maxLines)
    .textOverflow({ overflow: TextOverflow.Ellipsis })
    .ellipsisMode(EllipsisMode.END)
  }
}

@Component
export struct PLVLWChatQuoteContentLayout {
  quote: PLVChatQuoteDataBean = lateInit()
  @State private imageUrl: ResourceStr | undefined = undefined
  @State private imageWidth: number = 80
  @State private imageHeight: number = 80

  aboutToAppear(): void {
    this.imageUrl = this.quote.image?.url
    const imageSize = chatItemImageDisplaySize({
      width: this.quote.image?.width ?? 80,
      height: this.quote.image?.height ?? 80
    })
    this.imageWidth = imageSize.width
    this.imageHeight = imageSize.height
  }

  build() {
    Column() {
      Text() {
        Span(`${this.quote.nick}: `)
        if (!this.quote.image) {
          if (this.quote.msgType === 'file') {
            Span(this.quote.fileData?.name)
          } else {
            ForEach(
              PLVTextUtils.parseString(this.quote.content),
              (parsed: string) => {
                if (!PLVLWFaceManager.hasFace(parsed)) {
                  Span(parsed)
                } else {
                  ImageSpan(PLVLWFaceManager.getFace(parsed))
                    .width(12)
                    .height(12)
                    .verticalAlign(ImageSpanAlignment.CENTER)
                }
              }
            )
          }
        }
      }
      .fontSize(12)
      .fontColor($r('app.color.plvlw_chat_content_quote_speak_message_color'))
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .ellipsisMode(EllipsisMode.END)

      if (this.imageUrl) {
        Image(this.imageUrl)
          .width(this.imageWidth)
          .height(this.imageHeight)
          .objectFit(ImageFit.Contain)
          .margin({
            top: 6
          })
      }
    }
    .alignItems(HorizontalAlign.Start)
  }
}

@Component
export struct PLVLWChatSpeakOverLengthLayout {
  message: PLVSpeakEvent | PLVHistorySpeakEvent = lateInit()
  @Consume('chatItemActionCallback') chatItemActionCallback: ChatItemActionCallback

  build() {
    Row() {
      Text($r('app.string.plvlw_chat_copy'))
        .height(PLVCommonConstants.FULL_PERCENT)
        .textAlign(TextAlign.Center)
        .fontColor('#CCFFFEFC')
        .fontSize(14)
        .layoutWeight(1)
        .onClick(() => {
          this.chatItemActionCallback.onClickCopy?.(this.message)
        })
      Blank()
        .width(1)
        .color($r('app.color.plvlw_chat_content_quote_message_divider_color'))
      Text($r('app.string.plvlw_chat_more'))
        .height(PLVCommonConstants.FULL_PERCENT)
        .textAlign(TextAlign.Center)
        .fontColor('#CCFFFEFC')
        .fontSize(14)
        .layoutWeight(1)
        .onClick(() => {
          this.chatItemActionCallback.onClickOverLengthShowFullMessage?.(this.message)
        })
    }
    .alignItems(VerticalAlign.Center)
    .height(28)
  }
}

interface LongPressPopupProps {
  copy?: LongPressPopupPropsItem
  reply?: LongPressPopupPropsItem
}

interface LongPressPopupPropsItem {
  show?: boolean
  onClick?: () => void
}

@Builder
export function ChatContentItemLongPressPopup(props?: LongPressPopupProps) {
  Row() {
    if (props?.copy?.show) {
      Text($r('app.string.plvlw_chat_copy'))
        .fontSize(12)
        .fontColor('#F0F1F5')
        .onClick(() => {
          props?.copy?.onClick?.()
        })
    }

    if (props?.copy?.show && (props?.reply?.show)) {
      Divider()
        .vertical(true)
        .width(1)
        .height(20)
        .color('#2FCCCCCC')
        .margin({
          left: 11,
          right: 11
        })
    }

    if (props?.reply?.show) {
      Text($r('app.string.plvlw_chat_reply'))
        .fontSize(12)
        .fontColor('#F0F1F5')
        .onClick(() => {
          props?.reply?.onClick?.()
        })
    }
  }
  .padding({
    left: 14,
    right: 14,
    top: 6,
    bottom: 6
  })
}

export function chatMessageAvatar(avatar: string | undefined, viewerType: string | undefined): ResourceStr {
  if (!isTextBlank(avatar)) {
    return PLVTextUtils.fixPic(avatar)
  }
  switch (viewerType) {
    case PLVUserType.USERTYPE_TEACHER:
      return $r('app.media.plvlw_chatroom_ic_teacher')
    case PLVUserType.USERTYPE_ASSISTANT:
      return $r('app.media.plvlw_chatroom_ic_assistant')
    case PLVUserType.USERTYPE_GUEST:
      return $r('app.media.plvlw_chatroom_ic_guest')
    default:
      return $r('app.media.plvlw_chatroom_ic_viewer')
  }
}

export function actorBackgroundColor(viewerType: string | undefined): ResourceColor {
  switch (viewerType) {
    case PLVUserType.USERTYPE_TEACHER:
      return $r('app.color.plvlw_chat_actor_background_teacher')
    case PLVUserType.USERTYPE_ASSISTANT:
      return $r('app.color.plvlw_chat_actor_background_assistant')
    case PLVUserType.USERTYPE_GUEST:
      return $r('app.color.plvlw_chat_actor_background_guest')
    case PLVUserType.USERTYPE_MANAGER:
      return $r('app.color.plvlw_chat_actor_background_manager')
  }
  return Color.Transparent
}

export function nickForegroundColor(
  viewerType: string | undefined,
  defaultColor: ResourceColor = $r('app.color.plvlw_chat_name_foreground_viewer')
): ResourceColor {
  switch (viewerType) {
    case PLVUserType.USERTYPE_TEACHER:
      return $r('app.color.plvlw_chat_name_foreground_teacher')
    case PLVUserType.USERTYPE_ASSISTANT:
      return $r('app.color.plvlw_chat_name_foreground_assistant')
    case PLVUserType.USERTYPE_GUEST:
      return $r('app.color.plvlw_chat_name_foreground_guest')
    case PLVUserType.USERTYPE_MANAGER:
      return $r('app.color.plvlw_chat_name_foreground_manager')
  }
  return defaultColor
}

export interface Size {
  width: number;
  height: number;
}

export const chatItemImageMaxSize = 80

export const chatItemImageMinSize = 50

export function chatItemImageDisplaySize(sourceSize: Size): Size {
  const width = extendNumber(sourceSize.width).coerceAtLeast_ext(1)
  const height = extendNumber(sourceSize.height).coerceAtLeast_ext(1)
  const ratio = width / height
  let outWidth: number = width
  let outHeight: number = height
  if (ratio > 1) {
    outWidth = chatItemImageMaxSize
    outHeight = extendNumber(outWidth / ratio).coerceAtLeast_ext(chatItemImageMinSize)
  } else if (ratio < 1) {
    outHeight = chatItemImageMaxSize
    outWidth = extendNumber(outHeight * ratio).coerceAtLeast_ext(chatItemImageMinSize)
  } else {
    outWidth = chatItemImageMaxSize
    outHeight = chatItemImageMaxSize
  }
  return {
    width: outWidth,
    height: outHeight
  }
}

export class ChatItemActionCallback {
  onClickCopy?: (event: PLVSpeakEvent | PLVHistorySpeakEvent | PLVLocalSpeakEvent | PLVLocalQuizEvent | PLVTAnswerEvent) => void
  onClickReply?: (event: IPLVCanReplyEvent) => void
  onClickImage?: (event: PLVChatImgEvent | PLVHistoryChatImgEvent | PLVEmotionEvent | PLVTAnswerEvent | PLVChatPlaybackDataVO) => void
  onClickFileShare?: (event: PLVSpeakEvent | PLVHistoryFileShareEvent) => void
  onClickRedPaper?: (event: PLVRedPaperEvent) => void
  onClickOverLengthShowFullMessage?: (event: PLVSpeakEvent | PLVHistorySpeakEvent) => void
}