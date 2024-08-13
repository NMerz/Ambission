package ambission.ambission

import android.content.Context
import android.util.Log
import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Delete
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverter
import androidx.room.TypeConverters
import androidx.room.Upsert
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.flow.Flow

@Database(entities = [CreatedVideo::class, Inputs::class], version = 6)
@TypeConverters(AppDatabaseConverters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun createdVideoDao(): CreatedVideoDao
    abstract fun inputsDao(): InputsDao
    companion object {
        private var db: AppDatabase? = null

        fun getSharedDatabase(context: Context): AppDatabase {
            return db ?: synchronized(this) {
                Log.i("db", "made new db")
                val newDb = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "app_database"
                )
                    .allowMainThreadQueries() //TODO: fix this later when I have brainpower to learn Kotlin's coroutines
                    .addMigrations(MIGRATION_1_2)
                    .build()
                db = newDb
                Log.i("db", db.toString())
                return newDb
            }
        }

        fun getSharedDatabase(): AppDatabase {
            Log.i("db", db.toString())
            if ((db != null)) {
                return db as AppDatabase
            }
            throw InstantiationException()
        }

        //TODO: automigration should be a newer feature, look into that instead
        private val MIGRATION_1_2 = object : Migration(5, 6) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("CREATE TABLE Inputs(input TEXT NOT NULL, contents TEXT NOT NULL, PRIMARY KEY(`input`))")
            }
        }
    }
}

@Dao
interface InputsDao {
    @Query("SELECT contents FROM Inputs WHERE input = 'resume' LIMIT 1")
    fun getResume(): Flow<String>

    @Upsert
    fun setInput(input: Inputs)
}


@Dao
interface CreatedVideoDao {
    @Query("SELECT * FROM CreatedVideo")
    fun getAll(): Flow<List<CreatedVideo>>

    @Insert
    fun insertAll(vararg createdVideo: CreatedVideo)

    @Delete
    fun delete(createdVideo: CreatedVideo)

    @Query("SELECT * FROM CreatedVideo WHERE uid = :uid")
    fun getVideoSnapshot(uid: String): CreatedVideo

    @Query("SELECT * FROM CreatedVideo WHERE uid = :uid")
    fun getVideo(uid: String): CreatedVideo

    @Query("UPDATE CreatedVideo SET type_specific_input = :typeSpecificInput WHERE uid = :uid")
    fun updateTypeSpecificInput(uid: String, typeSpecificInput: Map<String, String>)

    @Query("UPDATE CreatedVideo SET unified_script = :script WHERE uid = :uid")
    fun updateUnifiedScript(uid: String, script: String)

    @Query("UPDATE CreatedVideo SET segments = :segments, segment_texts = :segmentTexts WHERE uid = :uid")
    fun setSegmentScripts(uid: String, segments: List<String>, segmentTexts: Map<String, String>)

    @Query("UPDATE CreatedVideo SET segment_urls = :segmentUrls WHERE uid = :uid")
    fun setSegmentUrls(uid: String, segmentUrls: Map<String, String>)

    @Query("UPDATE CreatedVideo SET segment_texts = :segmentTexts WHERE uid = :uid")
    fun setSegmentTexts(uid: String, segmentTexts: Map<String, String>)
}


@Entity
data class Inputs(
    @PrimaryKey val input: String,
    @ColumnInfo(name = "contents") val contents: String,
)

@Entity
data class CreatedVideo(
    @PrimaryKey val uid: String,
    @ColumnInfo(name = "video_title") val videoTitle: String,
    @ColumnInfo(name = "nominal_type") val nominalType: String,
    @ColumnInfo(name = "unified_script") val unifiedScript: String,
    @ColumnInfo(name = "type_specific_input", defaultValue = "{}") val typeSpecificInput: Map<String, String>,
    @ColumnInfo(name = "segments", defaultValue = "[]") val segments: List<String> = ArrayList(),
    @ColumnInfo(name = "segment_texts", defaultValue = "{}") val segmentTexts: Map<String, String> = HashMap(),
    @ColumnInfo(name = "segment_urls", defaultValue = "{}") val segmentUrls: Map<String, String> = HashMap(),
    )

class AppDatabaseConverters {
    @TypeConverter
    fun storeStringMap(value: Map<String, String>?): String? {
        Log.d("conversion", value.toString() + ", " + Gson().toJson(value))
        return Gson().toJson(value)
    }

    @TypeConverter
    fun resurrectStringMap(mapAsString: String?): Map<String, String>? {
        return Gson().fromJson(mapAsString, object : TypeToken<Map<String, String>>() {}.type)
    }

    @TypeConverter
    fun storeStringList(value: List<String>?): String? {
        return Gson().toJson(value)
    }

    @TypeConverter
    fun resurrectStringList(listAsString: String?): List<String>? {
        return Gson().fromJson(listAsString, object : TypeToken<List<String>>() {}.type)
    }
}