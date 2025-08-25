import {
  PLVBaseIdEvent,
  PLVChatImgEvent,
  PLVEmotionEvent,
  PLVHistoryChatImgEvent,
  PLVHistoryFileShareEvent,
  PLVHistoryRedPaperEvent,
  PLVHistorySpeakEvent,
  PLVLocalQuizEvent,
  PLVLocalSpeakEvent,
  PLVRedPaperEvent,
  PLVRedPaperResultEvent,
  PLVRewardEvent,
  PLVSpeakEvent,
  PLVTAnswerEvent
} from '@polyvharmony/live-scenes-sdk'
import { PLVLWChatContentItemFileShareMessage } from './item/PLVLWChatContentItemFileShareMessage'
import { PLVLWChatContentItemHistoryFileShareMessage } from './item/PLVLWChatContentItemHistoryFileShareMessage'
import { PLVLWChatContentItemHistoryImageMessage } from './item/PLVLWChatContentItemHistoryImageMessage'
import { PLVLWChatContentItemHistorySpeakMessage } from './item/PLVLWChatContentItemHistorySpeakMessage'
import { PLVLWChatContentItemImageMessage } from './item/PLVLWChatContentItemImageMessage'
import { PLVLWChatContentItemLocalEmotionMessage } from './item/PLVLWChatContentItemLocalEmotionMessage'
import { PLVLWChatContentItemLocalQuizMessage } from './item/PLVLWChatContentItemLocalQuizMessage'
import { PLVLWChatContentItemLocalSpeakMessage } from './item/PLVLWChatContentItemLocalSpeakMessage'
import { PLVLWChatContentItemQuizMessage } from './item/PLVLWChatContentItemQuizMessage'
import { PLVLWChatContentItemRedPaperMessage } from './item/PLVLWChatContentItemRedPaperMessage'
import { PLVLWChatContentItemRedPaperResultMessage } from './item/PLVLWChatContentItemRedPaperResultMessage'
import { PLVLWChatContentItemRewardMessage } from './item/PLVLWChatContentItemRewardMessage'
import { PLVLWChatContentItemSpeakMessage } from './item/PLVLWChatContentItemSpeakMessage'

@Component
export struct PLVLWChatContentItem {
  @ObjectLink message: PLVBaseIdEvent

  build() {
    Stack() {
      if (this.message instanceof PLVSpeakEvent && !this.message.isFileShareEvent()) {
        PLVLWChatContentItemSpeakMessage({
          message: this.message
        })
      }
      if (this.message instanceof PLVHistorySpeakEvent) {
        PLVLWChatContentItemHistorySpeakMessage({
          message: this.message
        })
      }
      if (this.message instanceof PLVLocalSpeakEvent) {
        PLVLWChatContentItemLocalSpeakMessage({
          message: this.message
        })
      }
      if (this.message instanceof PLVChatImgEvent) {
        PLVLWChatContentItemImageMessage({
          message: this.message
        })
      }
      if (this.message instanceof PLVHistoryChatImgEvent) {
        PLVLWChatContentItemHistoryImageMessage({
          message: this.message
        })
      }
      if (this.message instanceof PLVEmotionEvent) {
        PLVLWChatContentItemLocalEmotionMessage({
          message: this.message
        })
      }
      if (this.message instanceof PLVRewardEvent) {
        PLVLWChatContentItemRewardMessage({
          message: this.message
        })
      }
      if (this.message instanceof PLVRedPaperEvent || this.message instanceof PLVHistoryRedPaperEvent) {
        PLVLWChatContentItemRedPaperMessage({
          message: this.message
        })
      }
      if (this.message instanceof PLVRedPaperResultEvent) {
        PLVLWChatContentItemRedPaperResultMessage({
          message: this.message
        })
      }
      if (this.message instanceof PLVSpeakEvent && this.message.isFileShareEvent()) {
        PLVLWChatContentItemFileShareMessage({
          message: this.message
        })
      }
      if (this.message instanceof PLVHistoryFileShareEvent) {
        PLVLWChatContentItemHistoryFileShareMessage({
          message: this.message
        })
      }
      if (this.message instanceof PLVTAnswerEvent) {
        PLVLWChatContentItemQuizMessage({
          message: this.message
        })
      }
      if (this.message instanceof PLVLocalQuizEvent) {
        PLVLWChatContentItemLocalQuizMessage({
          message: this.message
        })
      }
    }
  }
}