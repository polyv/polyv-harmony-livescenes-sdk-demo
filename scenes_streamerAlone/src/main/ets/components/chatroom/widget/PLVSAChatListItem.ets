import {
  IPLVCanOverLenEvent,
  PLVBaseIdEvent,
  PLVCallback,
  PLVChannelData,
  PLVChatImgEvent,
  PLVChatPlaybackDataVO,
  PLVChatQuoteDataBean,
  PLVCommonConstants,
  PLVEmotionEvent,
  PLVHistoryChatImgEvent,
  PLVHistoryFileShareEvent,
  PLVHistoryRedPaperEvent,
  PLVHistorySpeakEvent,
  PLVImageBean,
  PLVLiveSceneSDK,
  PLVLocalQuizEvent,
  PLVLocalQuizPromptEvent,
  PLVLocalSpeakEvent,
  PLVLogger,
  PLVPPTShareFileDataBean,
  PLVRedPaperEvent,
  PLVRedPaperReceiveType,
  PLVRewardEvent,
  PLVSocketUserBean,
  PLVSpeakEvent,
  PLVTAnswerEvent,
  PLVToastUtils,
  PLVUserType,
  PLVUtils,
  PLVWebUtils,
  RedPaperReceiveTypeEvent
} from '@polyvharmony/live-scenes-sdk'
import { PLVSAChatOverLengthMessageDialog } from './PLVSAChatOverLengthMessageDialog'
import { PLVSAEventHub } from './PLVSAEventHub'
import PLVSAFaceManager from './PLVSAFaceManager'

const TAG = '[PLVSAChatListItem]'

@Preview
@Component
export struct PLVSAChatListItem {
  @ObjectLink itemData: PLVBaseIdEvent

  build() {
    if (this.itemData instanceof PLVSpeakEvent) { // 在线发言/在线文件分享
      PLVChatSpeakView({ itemData: this.itemData })
    } else if (this.itemData instanceof PLVChatImgEvent) { // 在线图片
      PLVChatImgView({ itemData: this.itemData })
    } else if (this.itemData instanceof PLVLocalSpeakEvent) { // 本地发言
      PLVChatLocalSpeakView({ itemData: this.itemData })
    } else if (this.itemData instanceof PLVLocalQuizEvent) { // 本地提问
      PLVChatLocalQuizView({ itemData: this.itemData })
    } else if (this.itemData instanceof PLVTAnswerEvent) { // 在线回答/历史提问和回答
      PLVChatTAnswerView({ itemData: this.itemData })
    } else if (this.itemData instanceof PLVLocalQuizPromptEvent) { // 本地提问提示语
      PLVChatLocalQuizPromptView({ itemData: this.itemData })
    } else if (this.itemData instanceof PLVHistorySpeakEvent) { // 历史发言
      PLVChatHistorySpeakView({ itemData: this.itemData })
    } else if (this.itemData instanceof PLVHistoryChatImgEvent) { // 历史图片/历史个性表情
      PLVChatHistoryChatImgView({ itemData: this.itemData })
    } else if (this.itemData instanceof PLVRewardEvent) { // 在线打赏/历史打赏
      PLVChatRewardView({ itemData: this.itemData })
    } else if (this.itemData instanceof PLVEmotionEvent) { // 在线个性表情
      PLVChatEmotionView({ itemData: this.itemData })
    } else if (this.itemData instanceof PLVHistoryFileShareEvent) { // 历史文件分享
      PLVChatHistoryFileShareView({ itemData: this.itemData })
    } else if (this.itemData instanceof PLVRedPaperEvent
      || this.itemData instanceof PLVHistoryRedPaperEvent) { // 在线口令红包/历史口令红包
      PLVChatRedPaperView({ itemData: this.itemData })
    } else if (this.itemData instanceof PLVChatPlaybackDataVO) { // 聊天回放消息
      PLVChatPlaybackView({ itemData: this.itemData })
    }
  }
}

@Component
export struct PLVChatSpeakView {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @ObjectLink itemData: PLVSpeakEvent
  @State nick: string | Resource | undefined = undefined
  @State actor: string | undefined = undefined
  @State userType: string | undefined = undefined
  @State fullMessage: string | undefined = undefined
  moreDialogController?: CustomDialogController = new CustomDialogController({
    builder: PLVSAChatOverLengthMessageDialog({
      nick: this.nick,
      actor: this.actor,
      userType: this.userType,
      fullMessage: this.fullMessage
    }),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })

  aboutToAppear(): void {
    this.nick = generateNickByUser(this.itemData.user)
    this.actor = this.itemData.user?.getActor()
    this.userType = this.itemData.user?.userType
  }

  build() {
    messageView(
      this.itemData.isFileShareEvent() ? this.itemData.fileData?.name : this.itemData.values?.[0],
      this.actor,
      this.userType,
      this.nick,
      this.itemData.isFileShareEvent() ? toImageBeanForFileShare(this.itemData.fileData) : undefined,
      this.itemData.quote,
      this.sdk?.chatroomManager.quoteReplyEnabled ? this.itemData._replyQuoteBean.get() : undefined,
      this.itemData.parsedData,
      this.itemData.isFileShareEvent() ? this.itemData.fileData?.url : undefined,
      this.itemData._isOverLengthFoldingMessage.get(),
      overLengthCopyClick(this.itemData.values?.[0], this.itemData, this.sdk),
      overLengthMoreClick(this.itemData.values?.[0], this.itemData, this.sdk, (fullMessage: string) => {
        this.fullMessage = fullMessage
        this.moreDialogController?.open()
      })
    )
  }
}

@Component
export struct PLVChatImgView {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @ObjectLink itemData: PLVChatImgEvent

  build() {
    messageView(
      undefined,
      this.itemData.user?.getActor(),
      this.itemData.user?.userType,
      generateNick(this.itemData.user, this.sdk?.channelData),
      PLVImageBean.toImageBeanForChatImg(this.itemData.values?.[0]),
      undefined,
      this.sdk?.chatroomManager.quoteReplyEnabled ? this.itemData._replyQuoteBean.get() : undefined
    )
  }
}

@Component
export struct PLVChatLocalSpeakView {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @ObjectLink itemData: PLVLocalSpeakEvent
  @State nick: string | Resource | undefined = undefined
  @State actor: string | undefined = undefined
  @State userType: string | undefined = undefined
  @State fullMessage: string | undefined = undefined
  moreDialogController?: CustomDialogController = new CustomDialogController({
    builder: PLVSAChatOverLengthMessageDialog({
      nick: this.nick,
      actor: this.actor,
      userType: this.userType,
      fullMessage: this.fullMessage
    }),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })

  aboutToAppear(): void {
    this.nick = generateNickByChannelData(this.channelData)
    this.actor = this.channelData?.viewerActor
    this.userType = this.channelData?.viewerType
  }

  build() {
    messageView(
      this.itemData.speakMessage,
      this.actor,
      this.userType,
      this.nick,
      undefined,
      this.itemData.quote,
      this.sdk?.chatroomManager.quoteReplyEnabled ? this.itemData._replyQuoteBean.get() : undefined,
      this.itemData.parsedData,
      undefined,
      this.itemData._isOverLengthFoldingMessage.get(),
      overLengthCopyClick(this.itemData.speakMessage, undefined, this.sdk),
      overLengthMoreClick(this.itemData.speakMessage, undefined, this.sdk, (fullMessage: string) => {
        this.fullMessage = fullMessage
        this.moreDialogController?.open()
      })
    )
  }
}

@Component
export struct PLVChatLocalQuizView {
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @ObjectLink itemData: PLVLocalQuizEvent

  build() {
    messageView(
      this.itemData.quizMessage,
      this.channelData?.viewerActor,
      this.channelData?.viewerType,
      generateNickByChannelData(this.channelData),
      undefined,
      undefined,
      undefined,
      this.itemData.parsedData
    )
  }
}

@Component
export struct PLVChatTAnswerView {
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @ObjectLink itemData: PLVTAnswerEvent

  build() {
    messageView(
      this.itemData.isImgType() ? undefined : this.itemData.content,
      this.itemData.user?.getActor(),
      this.itemData.user?.userType,
      generateNick(this.itemData.user, this.channelData),
      this.itemData.isImgType() ? this.itemData.image : undefined,
      undefined,
      undefined,
      this.itemData.parsedData
    )
  }
}

@Component
export struct PLVChatLocalQuizPromptView {
  @ObjectLink itemData: PLVLocalQuizPromptEvent

  build() {
    promptView(this.itemData.prompt)
  }
}

@Component
export struct PLVChatHistorySpeakView {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @ObjectLink itemData: PLVHistorySpeakEvent
  @State nick: string | Resource | undefined = undefined
  @State actor: string | undefined = undefined
  @State userType: string | undefined = undefined
  @State fullMessage: string | undefined = undefined
  moreDialogController?: CustomDialogController = new CustomDialogController({
    builder: PLVSAChatOverLengthMessageDialog({
      nick: this.nick,
      actor: this.actor,
      userType: this.userType,
      fullMessage: this.fullMessage
    }),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })

  aboutToAppear(): void {
    this.nick = generateNick(this.itemData.user, this.channelData)
    this.actor = this.itemData.user?.getActor()
    this.userType = this.itemData.user?.userType
  }

  build() {
    messageView(
      this.itemData.content,
      this.actor,
      this.userType,
      this.nick,
      undefined,
      this.itemData.quote,
      this.sdk?.chatroomManager.quoteReplyEnabled ? this.itemData._replyQuoteBean.get() : undefined,
      this.itemData.parsedData,
      undefined,
      this.itemData._isOverLengthFoldingMessage.get(),
      overLengthCopyClick(this.itemData.content, this.itemData, this.sdk),
      overLengthMoreClick(this.itemData.content, this.itemData, this.sdk, (fullMessage: string) => {
        this.fullMessage = fullMessage
        this.moreDialogController?.open()
      })
    )
  }
}

@Component
export struct PLVChatHistoryChatImgView {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @ObjectLink itemData: PLVHistoryChatImgEvent

  build() {
    messageView(
      undefined,
      this.itemData.user?.getActor(),
      this.itemData.user?.userType,
      generateNick(this.itemData.user, this.channelData),
      PLVImageBean.toImageBeanForChatImg(this.itemData.content),
      undefined,
      this.sdk?.chatroomManager.quoteReplyEnabled ? this.itemData._replyQuoteBean.get() : undefined
    )
  }
}

@Component
export struct PLVChatRewardView {
  @ObjectLink itemData: PLVRewardEvent

  build() {
    rewardView(this.itemData)
  }
}

@Component
export struct PLVChatEmotionView {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @ObjectLink itemData: PLVEmotionEvent

  build() {
    messageView(
      undefined,
      this.itemData.user?.getActor(),
      this.itemData.user?.userType,
      generateNick(this.itemData.user, this.channelData),
      PLVImageBean.toImageBeanForEmotion(this.itemData, this.sdk?.chatroomManager.emotions),
      undefined,
      this.sdk?.chatroomManager.quoteReplyEnabled ? this.itemData._replyQuoteBean.get(this.sdk?.chatroomManager.emotions) : undefined
    )
  }
}

@Component
export struct PLVChatHistoryFileShareView {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @ObjectLink itemData: PLVHistoryFileShareEvent

  build() {
    messageView(
      this.itemData.fileData?.name,
      this.itemData.user?.getActor(),
      this.itemData.user?.userType,
      generateNickByUser(this.itemData.user),
      toImageBeanForFileShare(this.itemData.fileData),
      undefined,
      this.sdk?.chatroomManager.quoteReplyEnabled ? this.itemData._replyQuoteBean.get() : undefined,
      undefined,
      this.itemData.fileData?.url
    )
  }
}

@Component
export struct PLVChatRedPaperView {
  @ObjectLink itemData: PLVRedPaperEvent
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined

  aboutToAppear(): void {
    this.sdk?.redpackManager.geLocalCachedReceiveStatus(this.itemData.redpackId)
      .then((value) => {
        this.itemData.receiveType = PLVRedPaperReceiveType.getValue(value as RedPaperReceiveTypeEvent)
        this.sdk?.redpackManager.cacheRedPaper(this.itemData)
      })
  }

  build() {
    redPaperView(
      this.itemData,
      () => {
        this.sdk?.interactManager?.receiveRedPaper(this.itemData)
      }
    )
  }
}

@Component
export struct PLVChatPlaybackView {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @Link itemData: PLVChatPlaybackDataVO

  build() {
    messageView(
      this.itemData.isImgMsgType() ? undefined : this.itemData.content,
      this.itemData.actor,
      this.itemData.userType,
      generateNick(this.itemData.user, this.channelData),
      this.itemData.isImgMsgType() ? PLVImageBean.toImageBeanForChatImg(this.itemData.chatImgContent) : undefined,
      this.itemData.chatQuote,
      undefined,
      this.itemData.parsedData
    )
  }
}

/**
 * 聊天消息View
 * @param speakMsg 发言内容/提问内容/回答内容/文件分享的文件名
 * @param actor 用户头衔
 * @param userType 用户类型
 * @param nick 用户昵称
 * @param imgBean 图片/个性表情/文件分享的图片
 * @param quote 消息是否包含回复内容
 * @param reply 消息是否可以被回复的内容
 * @param parsedData 将speakMsg按表情文本解析后的数据
 * @param fileUrl 文件分享的url
 * @param isOverLengthFoldingMessage 是否超长消息
 * @param overLengthCopyClick 超长消息复制点击回调
 * @param overLengthMoreClick 超长消息更多点击回调
 */
@Builder
function messageView(
  speakMsg?: string,
  actor?: string,
  userType?: string,
  nick?: string | Resource,
  imgBean?: PLVImageBean,
  quote?: PLVChatQuoteDataBean,
  reply?: PLVChatQuoteDataBean,
  parsedData?: string[],
  fileUrl?: string,
  isOverLengthFoldingMessage?: boolean,
  overLengthCopyClick?: PLVCallback,
  overLengthMoreClick?: PLVCallback
) {
  Column() {
    ColumnSplit() {
      if (quote) {
        Column() {
          Text() {
            Span(quote.nick + ': ')
              .fontColor('#FFFFFF')
              .fontSize(12)
            if (quote.isTextEvent()) {
              if (quote.parsedData) {
                ForEach(quote.parsedData, (data: string) => {
                  if (typeof PLVSAFaceManager.getFace(data) === 'string') {
                    Span(PLVSAFaceManager.getFace(data))
                      .fontColor('#FFFFFF')
                      .fontSize(12)
                  } else {
                    ImageSpan(PLVSAFaceManager.getFace(data))
                      .width(18)
                      .height(18)
                      .verticalAlign(ImageSpanAlignment.CENTER)
                  }
                })
              } else {
                Span(quote.content)
                  .fontColor('#FFFFFF')
                  .fontSize(12)
              }
            } else if (quote.isFileShareEvent()) {
              Span(quote.fileData?.name)
                .fontColor('#FFFFFF')
                .fontSize(12)
            }
          }
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: !quote.isTextEvent() ? 166 : Infinity })

          if (quote.isChatImgEvent()) {
            imageView(quote.image)
          } else if (quote.isFileShareEvent()) {
            imageView(toImageBeanForFileShare(quote.fileData), 8)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
      }

      Column() {
        Text() {
          if (actor && PLVSocketUserBean.isSpecialType(userType)) {
            Span(`  ${actor}  `)
              .fontColor('#FFFFFF')
              .textBackgroundStyle({ color: getActorBgByUserType(userType), radius: 7 })
              .fontSize(10)
          }
          Span(nick)
            .fontColor('#FFD16B')
            .fontSize(12)
          if (parsedData) {
            ForEach(parsedData, (data: string) => {
              if (typeof PLVSAFaceManager.getFace(data) === 'string') {
                Span(PLVSAFaceManager.getFace(data))
                  .fontColor('#FFFFFF')
                  .fontSize(12)
              } else {
                ImageSpan(PLVSAFaceManager.getFace(data))
                  .width(18)
                  .height(18)
                  .verticalAlign(ImageSpanAlignment.CENTER)
              }
            })
          } else if (speakMsg) {
            Span(speakMsg)
              .fontColor('#FFFFFF')
              .fontSize(12)
          }
        }
        .maxLines(speakMsg && isOverLengthFoldingMessage ? 5 : Infinity)
        .constraintSize({ maxWidth: imgBean ? 166 : Infinity, minHeight: 24 })

        imageView(imgBean, fileUrl ? 8 : 0)
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)

      if (speakMsg && isOverLengthFoldingMessage) {
        Row() {
          Text($r('app.string.plvsa_chat_copy'))
            .height(PLVCommonConstants.FULL_PERCENT)
            .textAlign(TextAlign.Center)
            .fontColor('#CCFFFEFC')
            .margin({ left: 8, right: 8 })
            .fontSize(14)
            .layoutWeight(1)
            .onClick(() => {
              overLengthCopyClick?.()
            })
          Divider()
            .color('#4DD8D8D8')
            .height(15)
            .strokeWidth(1)
            .vertical(true)
          Text($r('app.string.plvsa_chat_more'))
            .height(PLVCommonConstants.FULL_PERCENT)
            .textAlign(TextAlign.Center)
            .fontColor('#CCFFFEFC')
            .margin({ left: 8, right: 8 })
            .fontSize(14)
            .layoutWeight(1)
            .onClick(() => {
              overLengthMoreClick?.()
            })
        }
        .height(28)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Start)
      }
    }
    .hitTestBehavior(HitTestMode.None)
    .divider({ startMargin: 4, endMargin: 4 })
  }
  .padding({
    left: 8,
    right: 8,
    top: 4,
    bottom: 4
  })
  .alignItems(HorizontalAlign.Start)
  .justifyContent(FlexAlign.Start)
  .constraintSize({ minHeight: 20 })
  .backgroundColor('#33000000')
  .borderRadius(14)
  .bindContextMenu(((speakMsg && !isOverLengthFoldingMessage) || reply) ? menuView(speakMsg, reply, isOverLengthFoldingMessage) : undefined, ResponseType.LongPress, {
    backgroundBlurStyle: BlurStyle.NONE,
    backgroundColor: '#BF1B202D'
  })
  .onClick(() => {
    if (fileUrl) {
      PLVWebUtils.openWebLink(fileUrl)
    }
  })
}

@Builder
function menuView(speakMsg?: string, reply?: PLVChatQuoteDataBean, isOverLengthFoldingMessage?: boolean) {
  Column() {
    ColumnSplit() {
      if (speakMsg && !isOverLengthFoldingMessage) {
        Button($r('app.string.plvsa_chat_copy'))
          .backgroundColor(Color.Transparent)
          .fontColor('#F0F1F5')
          .fontSize(12)
          .onClick(() => {
            PLVUtils.copyText(speakMsg).then(() => {
              PLVToastUtils.shortShow($r('app.string.plvsa_chat_copy_success'))
            })
          })
      }
      if (reply) {
        Button($r('app.string.plvsa_chat_answer'))
          .backgroundColor(Color.Transparent)
          .fontColor('#F0F1F5')
          .fontSize(12)
          .onClick(() => {
            PLVSAEventHub.emit(`plvsa_chat_reply`, reply)
          })
      }
    }
    .divider({ startMargin: 2, endMargin: 2 })
  }
  .alignItems(HorizontalAlign.Center)
  .justifyContent(FlexAlign.Start)
}

@Builder
function imageView(imgBean?: PLVImageBean, marginLeft?: number) {
  if (imgBean) {
    Image(imgBean.url)
      .alt($r('app.media.plvsa_img_site'))
      .width(adjustChatImgWH(imgBean.width, imgBean.height, 80, 60)[0])
      .height(adjustChatImgWH(imgBean.width, imgBean.height, 80, 60)[1])
      .margin({ left: marginLeft ? marginLeft : 0 })
      .objectFit(ImageFit.Auto)
      .autoResize(true)
      .borderRadius(6)
      .draggable(false)
      .onError((err) => {
        PLVLogger.printError(TAG, `chat image url=${imgBean.url} load error`, new Error(err.message))
      })
  }
}

@Builder
function promptView(prompt?: string | Resource) {
  Text(prompt)
    .fontColor('#FFD16B')
    .fontSize(12)
    .constraintSize({ minHeight: 20 })
    .padding({
      left: 8,
      right: 8,
      top: 4,
      bottom: 4
    })
    .backgroundColor('#A8333333')
    .borderRadius(6)
}

@Builder
function rewardView(rewardEvent: PLVRewardEvent) {
  Text() {
    Span(rewardEvent.content?.unick + ' ')
      .fontSize(12)
      .fontColor('#ffffff')
    Span($r('app.string.plvsa_reward_give', ' '))
      .fontSize(12)
      .fontColor('#ffffff')
    ImageSpan(rewardEvent.content?.getGimg())
      .width(20)
      .height(20)
      .verticalAlign(ImageSpanAlignment.CENTER)
    if (rewardEvent.content?.goodNum && rewardEvent.content.goodNum > 1) {
      Span(' x' + rewardEvent.content.goodNum)
        .fontSize(12)
        .fontColor('#ffffff')
    }
  }
  .constraintSize({ minHeight: 20 })
  .padding({
    left: 8,
    right: 8,
    top: 4,
    bottom: 4
  })
  .backgroundColor('#A8333333')
  .borderRadius(6)
}

@Builder
function redPaperView(redPaperEvent: PLVRedPaperEvent, getRedPaperClick?: PLVCallback) {
  Text() {
    ImageSpan($r('app.media.plvsa_chatroom_red_pack_icon'))
      .width(20)
      .height(20)
      .verticalAlign(ImageSpanAlignment.CENTER)
    Span($r('app.string.plvsa_red_paper_send_msg', redPaperEvent.user?.nick))
      .fontSize(12)
      .fontColor('#FFFFFFFF')
    Span(redPaperEvent.getTypeName())
      .fontSize(12)
      .fontColor('#FFFFFFFF')
    Span($r('app.string.plvsa_red_paper_dot'))
      .fontSize(12)
      .fontColor('#FFFFFFFF')
    Span($r('app.string.plv_red_paper_get'))
      .fontSize(12)
      .fontColor('#FF5459')
      .onClick((event) => {
        getRedPaperClick?.()
      })
  }
  .constraintSize({ minHeight: 20 })
  .padding({
    left: 8,
    right: 8,
    top: 4,
    bottom: 4
  })
  .backgroundColor('#A8333333')
  .borderRadius(6)
}

function generateNick(user?: PLVSocketUserBean, channelData?: PLVChannelData) {
  return channelData?.viewerId == user?.userId ? generateNickByChannelData(channelData) : generateNickByUser(user)
}

function generateNickByUser(user?: PLVSocketUserBean) {
  return (user?.getActor() && PLVSocketUserBean.isSpecialType(user?.userType) ? ' ' : '') + `${user?.nick}: `
}

function generateNickByChannelData(channelData?: PLVChannelData) {
  return $r('app.string.plvsa_chat_me', (channelData?.viewerActor && PLVSocketUserBean.isSpecialType(channelData?.viewerType) ? ' ' : '') + channelData?.viewerName, ': ')
}

export function getActorBgByUserType(userType?: string) {
  if (PLVUserType.USERTYPE_TEACHER == userType) {
    return '#F09343'
  } else if (PLVUserType.USERTYPE_ASSISTANT == userType) {
    return '#598FE5'
  } else if (PLVUserType.USERTYPE_GUEST == userType) {
    return '#EB6165'
  } else if (PLVUserType.USERTYPE_MANAGER == userType) {
    return '#33BBC5'
  }
  return ''
}

function adjustChatImgWH(widthVp: number, heightVp: number, maxVp: number, minVp: number) {
  const percentage = widthVp / heightVp
  if (percentage == 1) { // 方图
    if (widthVp < minVp) {
      widthVp = heightVp = minVp
    } else if (widthVp > maxVp) {
      widthVp = heightVp = maxVp
    }
  } else if (percentage < 1) { // 竖图
    heightVp = maxVp
    widthVp = Math.max(minVp, heightVp * percentage)
  } else { // 横图
    widthVp = maxVp
    heightVp = Math.max(minVp, widthVp / percentage)
  }
  return [widthVp, heightVp]
}

function toImageBeanForFileShare(fileShareBean?: PLVPPTShareFileDataBean): PLVImageBean {
  const imageBean = PLVImageBean.toImageBeanForFileShare(fileShareBean)
  imageBean.width = 120
  imageBean.height = 144
  switch (fileShareBean?.suffix) {
    case "ppt":
    case "pptx":
      imageBean.url = $r('app.media.plvsa_chatroom_file_share_ppt_icon')
      break
    case "doc":
    case "docx":
      imageBean.url = $r('app.media.plvsa_chatroom_file_share_doc_icon')
      break
    case "xls":
    case "xlsx":
      imageBean.url = $r('app.media.plvsa_chatroom_file_share_xls_icon')
      break
    case "pdf":
      imageBean.url = $r('app.media.plvsa_chatroom_file_share_pdf_icon')
      break
    default:
      break
  }
  return imageBean
}

function overLengthCopyClick(message?: string, overLenEvent?: IPLVCanOverLenEvent, sdk?: PLVLiveSceneSDK) {
  return () => {
    if (overLenEvent?.overLen) {
      overLenEvent._overLengthFullMessage.get((fullMessage) => {
        PLVUtils.copyText(fullMessage).then(() => {
          PLVToastUtils.shortShow($r('app.string.plvsa_chat_copy_success'))
        })
      }, sdk?.chatroomManager)
    } else {
      PLVUtils.copyText(message || '').then(() => {
        PLVToastUtils.shortShow($r('app.string.plvsa_chat_copy_success'))
      })
    }
  }
}

function overLengthMoreClick(message?: string, overLenEvent?: IPLVCanOverLenEvent, sdk?: PLVLiveSceneSDK, fullMessageCallback?: PLVCallback<string>) {
  return () => {
    if (overLenEvent?.overLen) {
      overLenEvent._overLengthFullMessage.get((fullMessage) => {
        fullMessageCallback?.(fullMessage)
      }, sdk?.chatroomManager)
    } else {
      fullMessageCallback?.(message || '')
    }
  }
}